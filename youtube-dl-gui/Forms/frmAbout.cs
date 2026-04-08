#nullable enable
namespace youtube_dl_gui;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
public partial class frmAbout : LocalizedForm {
    private const string AboutAuthor = "Ольга Шевелева";
    private const string AuthorGithub = "https://github.com/Murs2024";

    public frmAbout() {
        InitializeComponent();
        LoadLanguage();
        pbIcon.Image = Properties.Resources.AboutImage;
        pbIcon.Cursor = NativeMethods.SystemHandCursor;
        lbVersion.Text = $"v{Program.CurrentVersion}";
        llbCheckForUpdates.LinkVisited = Program.UpdateChecked;
        llbCheckForUpdates.Location = new(
            (this.ClientSize.Width - llbCheckForUpdates.Width) / 2,
            llbCheckForUpdates.Location.Y
        );

        if (Initialization.ScreenshotMode)
            this.FormClosing += (s, e) => this.Dispose();
    }

    public override void LoadLanguage() {
        lbHeader.Text = Language.ApplicationDisplayName;
        lbAboutBody.Text = string.Format(Language.lbAboutBody, AboutAuthor, Properties.Resources.BuildDate);
        llbCheckForUpdates.Text = Language.llbCheckForUpdates;
        this.Text = $"{Language.frmAbout} {Language.ApplicationDisplayName}";
    }

    private async void llbCheckForUpdates_LinkClicked(object sender, LinkLabelLinkClickedEventArgs e) {
        try {
            switch (await Updater.CheckForUpdate(chkForceCheckUpdate.Checked)) {
                case null: return;
                case false: {
                    Log.MessageBox((Program.CurrentVersion.IsBeta ? Language.dlgUpdateNoBetaUpdateAvailable : Language.dlgUpdateNoUpdateAvailable)
                        .Format(Program.CurrentVersion, Updater.LastChecked!.Version));
                } break;
                case true: {
                    Updater.ShowUpdateForm(false);
                } break;
            }

            Program.UpdateChecked = true;
            if (!Program.IsUpdating && this.IsHandleCreated)
                llbCheckForUpdates.Invoke(() => llbCheckForUpdates.LinkVisited = true);
        }
        catch (Exception ex) {
            if (ex is ThreadAbortException or OperationCanceledException or TaskCanceledException)
                return;

            Log.ReportException(ex);
        }
    }

    private void pbIcon_Click(object sender, EventArgs e) =>
        Process.Start(AuthorGithub);

    private void llbGithub_LinkClicked(object sender, LinkLabelLinkClickedEventArgs e) =>
        Process.Start(AuthorGithub);
}
