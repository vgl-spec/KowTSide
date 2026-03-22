<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class Login
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()>
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.btnClose = New System.Windows.Forms.PictureBox()
        Me.Label1 = New System.Windows.Forms.Label()
        Me.passtxtbox = New KowTSide.RoundedPanel()
        Me.RoundedTextBox1 = New KowTSide.RoundedTextBox()
        Me.emailBox = New KowTSide.RoundedTextBox()
        Me.BtnLogin = New KowTSide.RoundedButton()
        Me.passlbl = New System.Windows.Forms.Label()
        Me.emaillbl = New System.Windows.Forms.Label()
        CType(Me.btnClose, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.passtxtbox.SuspendLayout()
        Me.SuspendLayout()
        '
        'btnClose
        '
        Me.btnClose.BackColor = System.Drawing.Color.Transparent
        Me.btnClose.Image = Global.KowTSide.My.Resources.Resources.btnClose
        Me.btnClose.Location = New System.Drawing.Point(1168, 12)
        Me.btnClose.Name = "btnClose"
        Me.btnClose.Size = New System.Drawing.Size(100, 95)
        Me.btnClose.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom
        Me.btnClose.TabIndex = 1
        Me.btnClose.TabStop = False
        '
        'Label1
        '
        Me.Label1.AutoSize = True
        Me.Label1.BackColor = System.Drawing.Color.Transparent
        Me.Label1.Font = New System.Drawing.Font("Microsoft Sans Serif", 48.0!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.Label1.Location = New System.Drawing.Point(572, 69)
        Me.Label1.Name = "Label1"
        Me.Label1.Size = New System.Drawing.Size(232, 73)
        Me.Label1.TabIndex = 2
        Me.Label1.Text = "LOGIN"
        '
        'passtxtbox
        '
        Me.passtxtbox.BorderRadius = 20
        Me.passtxtbox.Controls.Add(Me.RoundedTextBox1)
        Me.passtxtbox.Controls.Add(Me.emailBox)
        Me.passtxtbox.Controls.Add(Me.BtnLogin)
        Me.passtxtbox.Controls.Add(Me.passlbl)
        Me.passtxtbox.Controls.Add(Me.emaillbl)
        Me.passtxtbox.Location = New System.Drawing.Point(391, 157)
        Me.passtxtbox.Name = "passtxtbox"
        Me.passtxtbox.Size = New System.Drawing.Size(532, 394)
        Me.passtxtbox.TabIndex = 0
        '
        'RoundedTextBox1
        '
        Me.RoundedTextBox1.BorderRadius = 15
        Me.RoundedTextBox1.IsPassword = False
        Me.RoundedTextBox1.Location = New System.Drawing.Point(77, 201)
        Me.RoundedTextBox1.Name = "RoundedTextBox1"
        Me.RoundedTextBox1.PlaceholderText = "Enter text..."
        Me.RoundedTextBox1.Size = New System.Drawing.Size(417, 56)
        Me.RoundedTextBox1.TabIndex = 10
        '
        'emailBox
        '
        Me.emailBox.BorderRadius = 15
        Me.emailBox.IsPassword = False
        Me.emailBox.Location = New System.Drawing.Point(74, 103)
        Me.emailBox.Name = "emailBox"
        Me.emailBox.PlaceholderText = "Enter text..."
        Me.emailBox.Size = New System.Drawing.Size(417, 56)
        Me.emailBox.TabIndex = 9
        '
        'BtnLogin
        '
        Me.BtnLogin.BackColor = System.Drawing.Color.Transparent
        Me.BtnLogin.BorderRadius = 20
        Me.BtnLogin.FillColor = System.Drawing.Color.LightGreen
        Me.BtnLogin.FlatAppearance.BorderSize = 0
        Me.BtnLogin.FlatStyle = System.Windows.Forms.FlatStyle.Flat
        Me.BtnLogin.Location = New System.Drawing.Point(160, 286)
        Me.BtnLogin.Name = "BtnLogin"
        Me.BtnLogin.Size = New System.Drawing.Size(238, 73)
        Me.BtnLogin.TabIndex = 8
        Me.BtnLogin.Text = "Enter"
        Me.BtnLogin.TextColor = System.Drawing.Color.Black
        Me.BtnLogin.UseVisualStyleBackColor = False
        '
        'passlbl
        '
        Me.passlbl.AutoSize = True
        Me.passlbl.BackColor = System.Drawing.Color.Transparent
        Me.passlbl.Location = New System.Drawing.Point(71, 176)
        Me.passlbl.Name = "passlbl"
        Me.passlbl.Size = New System.Drawing.Size(53, 13)
        Me.passlbl.TabIndex = 7
        Me.passlbl.Text = "Password"
        '
        'emaillbl
        '
        Me.emaillbl.AutoSize = True
        Me.emaillbl.BackColor = System.Drawing.Color.Transparent
        Me.emaillbl.Location = New System.Drawing.Point(74, 79)
        Me.emaillbl.Name = "emaillbl"
        Me.emaillbl.Size = New System.Drawing.Size(32, 13)
        Me.emaillbl.TabIndex = 4
        Me.emaillbl.Text = "Email"
        '
        'Login
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.BackgroundImage = Global.KowTSide.My.Resources.Resources.TeacherSideBGLog
        Me.ClientSize = New System.Drawing.Size(1280, 720)
        Me.Controls.Add(Me.Label1)
        Me.Controls.Add(Me.btnClose)
        Me.Controls.Add(Me.passtxtbox)
        Me.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None
        Me.Name = "Login"
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen
        Me.Text = "Form1"
        CType(Me.btnClose, System.ComponentModel.ISupportInitialize).EndInit()
        Me.passtxtbox.ResumeLayout(False)
        Me.passtxtbox.PerformLayout()
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub

    Friend WithEvents passtxtbox As RoundedPanel
    Friend WithEvents btnClose As PictureBox
    Friend WithEvents Label1 As Label
    Friend WithEvents emaillbl As Label
    Friend WithEvents passlbl As Label
    Friend WithEvents BtnLogin As RoundedButton
    Friend WithEvents emailBox As RoundedTextBox
    Friend WithEvents RoundedTextBox1 As RoundedTextBox
End Class
