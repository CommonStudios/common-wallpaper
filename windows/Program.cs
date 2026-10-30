// The cloud sea wallpaper for Windows: wallpaper.html in a WebView2 on every monitor, behind the desktop icons.
//
// Explorer draws the icons in a SHELLDLL_DefView window. Sending Progman the undocumented 0x052C message makes it
// create a WorkerW window behind that view, which is where wallpaper apps draw. Before Windows 11 24H2 that WorkerW is
// a top-level window right after the one holding the icons; from 24H2 on it is a child of Progman, and the wallpaper
// goes into Progman directly, just below the icons.
using System.Runtime.InteropServices;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;
using Microsoft.Win32;

static class Program
{
    static readonly List<Form> forms = new();
    static Task<CoreWebView2Environment>? environment;

    [STAThread]
    static void Main()
    {
        using var single = new Mutex(true, "CommonWallpaper", out var first);
        if (!first) return;
        ApplicationConfiguration.Initialize();
        SystemEvents.DisplaySettingsChanged += (_, _) => Fit();
        // Explorer restarting takes the desktop windows, and the wallpaper with them, down; it says so when it's back.
        using var explorer = new ExplorerWatcher(Fit);
        Fit();
        Application.Run();
    }

    // One window per monitor, rebuilt whenever monitors are added, removed, or change resolution or scaling.
    static void Fit()
    {
        foreach (var form in forms) form.Close();
        forms.Clear();
        var (parent, below) = DesktopParent();
        // The parent spans the whole virtual screen; children are placed relative to its top-left corner.
        var origin = SystemInformation.VirtualScreen.Location;
        foreach (var screen in Screen.AllScreens)
        {
            var bounds = screen.Bounds;
            bounds.Offset(-origin.X, -origin.Y);
            forms.Add(Wallpaper(parent, below, bounds));
        }
    }

    static Form Wallpaper(IntPtr parent, IntPtr below, Rectangle bounds)
    {
        var form = new Form { FormBorderStyle = FormBorderStyle.None, ShowInTaskbar = false, StartPosition = FormStartPosition.Manual, Bounds = bounds, BackColor = Color.FromArgb(0x11, 0x13, 0x12) };
        var web = new WebView2 { Dock = DockStyle.Fill, DefaultBackgroundColor = form.BackColor };
        form.Controls.Add(web);
        form.Load += async (_, _) =>
        {
            var dataDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "CommonWallpaper", "WebView2");
            environment ??= CoreWebView2Environment.CreateAsync(null, dataDir);
            await web.EnsureCoreWebView2Async(await environment);
            web.CoreWebView2.Settings.AreDefaultContextMenusEnabled = false;
            web.CoreWebView2.Settings.AreDevToolsEnabled = false;
            web.CoreWebView2.SetVirtualHostNameToFolderMapping("wallpaper.local", AppContext.BaseDirectory, CoreWebView2HostResourceAccessKind.Allow);
            web.CoreWebView2.Navigate("https://wallpaper.local/wallpaper.html");
        };
        form.Show();
        SetWindowLongPtr(form.Handle, GWL_STYLE, (IntPtr)(WS_CHILD | WS_VISIBLE));
        SetParent(form.Handle, parent);
        SetWindowPos(form.Handle, below == IntPtr.Zero ? HWND_TOP : below, bounds.X, bounds.Y, bounds.Width, bounds.Height, SWP_NOACTIVATE | SWP_SHOWWINDOW);
        return form;
    }

    // Where the wallpaper goes, and the window it sits just below (none before 24H2).
    static (IntPtr parent, IntPtr below) DesktopParent()
    {
        var progman = FindWindow("Progman", null);
        SendMessageTimeout(progman, 0x052C, IntPtr.Zero, IntPtr.Zero, SMTO_NORMAL, 1000, out _);
        SendMessageTimeout(progman, 0x052C, (IntPtr)0xD, (IntPtr)1, SMTO_NORMAL, 1000, out _);

        // Windows 11 24H2 and later: the WorkerW is Progman's child; draw in Progman, below the icons.
        if (FindWindowEx(progman, IntPtr.Zero, "WorkerW", null) != IntPtr.Zero)
            return (progman, FindWindowEx(progman, IntPtr.Zero, "SHELLDLL_DefView", null));

        // Earlier: the WorkerW that comes after the top-level window holding SHELLDLL_DefView.
        var workerw = IntPtr.Zero;
        EnumWindows((top, _) =>
        {
            if (FindWindowEx(top, IntPtr.Zero, "SHELLDLL_DefView", null) == IntPtr.Zero) return true;
            workerw = FindWindowEx(IntPtr.Zero, top, "WorkerW", null);
            return false;
        }, IntPtr.Zero);
        return (workerw != IntPtr.Zero ? workerw : progman, IntPtr.Zero);
    }

    // A hidden top-level window, there to hear Explorer's TaskbarCreated broadcast.
    sealed class ExplorerWatcher : NativeWindow, IDisposable
    {
        static readonly uint TaskbarCreated = RegisterWindowMessage("TaskbarCreated");
        readonly Action restarted;
        public ExplorerWatcher(Action restarted) { this.restarted = restarted; CreateHandle(new CreateParams()); }
        protected override void WndProc(ref Message m)
        {
            if (m.Msg == TaskbarCreated) restarted();
            base.WndProc(ref m);
        }
        public void Dispose() => DestroyHandle();
    }

    const int GWL_STYLE = -16;
    const long WS_CHILD = 0x40000000, WS_VISIBLE = 0x10000000;
    const uint SWP_NOACTIVATE = 0x0010, SWP_SHOWWINDOW = 0x0040, SMTO_NORMAL = 0;
    static readonly IntPtr HWND_TOP = IntPtr.Zero;
    delegate bool EnumWindowsProc(IntPtr hwnd, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr FindWindow(string cls, string? name);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string cls, string? name);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc proc, IntPtr lParam);
    [DllImport("user32.dll")] static extern IntPtr SendMessageTimeout(IntPtr hwnd, uint msg, IntPtr wParam, IntPtr lParam, uint flags, uint timeout, out IntPtr result);
    [DllImport("user32.dll")] static extern IntPtr SetParent(IntPtr child, IntPtr parent);
    [DllImport("user32.dll")] static extern IntPtr SetWindowLongPtr(IntPtr hwnd, int index, IntPtr value);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern uint RegisterWindowMessage(string name);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
}
