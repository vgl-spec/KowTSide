<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class MainPanel
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()> _
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
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        Me.FlowLayoutPanel1 = New System.Windows.Forms.FlowLayoutPanel()
        Me.welcome = New System.Windows.Forms.Label()
        Me.btnls1 = New System.Windows.Forms.Button()
        Me.btnls2 = New System.Windows.Forms.Button()
        Me.btnls3 = New System.Windows.Forms.Button()
        Me.signoutbtn = New KowTSide.RoundedButton()
        Me.SuspendLayout()
        '
        'FlowLayoutPanel1
        '
        Me.FlowLayoutPanel1.Location = New System.Drawing.Point(133, 156)
        Me.FlowLayoutPanel1.Name = "FlowLayoutPanel1"
        Me.FlowLayoutPanel1.Size = New System.Drawing.Size(1121, 474)
        Me.FlowLayoutPanel1.TabIndex = 0
        '
        'welcome
        '
        Me.welcome.AutoSize = True
        Me.welcome.BackColor = System.Drawing.Color.Transparent
        Me.welcome.Font = New System.Drawing.Font("Microsoft Sans Serif", 72.0!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.welcome.Location = New System.Drawing.Point(455, 21)
        Me.welcome.Name = "welcome"
        Me.welcome.Size = New System.Drawing.Size(471, 108)
        Me.welcome.TabIndex = 2
        Me.welcome.Text = "Welcome!"
        '
        'btnls1
        '
        Me.btnls1.Location = New System.Drawing.Point(40, 156)
        Me.btnls1.Name = "btnls1"
        Me.btnls1.Size = New System.Drawing.Size(75, 63)
        Me.btnls1.TabIndex = 3
        Me.btnls1.Text = "1"
        Me.btnls1.UseVisualStyleBackColor = True
        '
        'btnls2
        '
        Me.btnls2.Location = New System.Drawing.Point(40, 225)
        Me.btnls2.Name = "btnls2"
        Me.btnls2.Size = New System.Drawing.Size(75, 63)
        Me.btnls2.TabIndex = 4
        Me.btnls2.Text = "2"
        Me.btnls2.UseVisualStyleBackColor = True
        '
        'btnls3
        '
        Me.btnls3.Location = New System.Drawing.Point(40, 294)
        Me.btnls3.Name = "btnls3"
        Me.btnls3.Size = New System.Drawing.Size(75, 63)
        Me.btnls3.TabIndex = 5
        Me.btnls3.Text = "3"
        Me.btnls3.UseVisualStyleBackColor = True
        '
        'signoutbtn
        '
        Me.signoutbtn.BackColor = System.Drawing.Color.Transparent
        Me.signoutbtn.BorderRadius = 20
        Me.signoutbtn.FillColor = System.Drawing.Color.Salmon
        Me.signoutbtn.FlatAppearance.BorderSize = 0
        Me.signoutbtn.FlatStyle = System.Windows.Forms.FlatStyle.Flat
        Me.signoutbtn.Location = New System.Drawing.Point(548, 652)
        Me.signoutbtn.Name = "signoutbtn"
        Me.signoutbtn.Size = New System.Drawing.Size(250, 56)
        Me.signoutbtn.TabIndex = 1
        Me.signoutbtn.Text = "SignOut"
        Me.signoutbtn.TextColor = System.Drawing.Color.White
        Me.signoutbtn.UseVisualStyleBackColor = False
        '
        'MainPanel
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.BackgroundImage = Global.KowTSide.My.Resources.Resources.TeacherSideBGLog
        Me.ClientSize = New System.Drawing.Size(1280, 720)
        Me.Controls.Add(Me.btnls3)
        Me.Controls.Add(Me.btnls2)
        Me.Controls.Add(Me.btnls1)
        Me.Controls.Add(Me.welcome)
        Me.Controls.Add(Me.signoutbtn)
        Me.Controls.Add(Me.FlowLayoutPanel1)
        Me.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None
        Me.Name = "MainPanel"
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen
        Me.Text = "MainPanel"
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub

    Friend WithEvents FlowLayoutPanel1 As FlowLayoutPanel
    Friend WithEvents signoutbtn As RoundedButton
    Friend WithEvents welcome As Label
    Friend WithEvents btnls1 As Button
    Friend WithEvents btnls2 As Button
    Friend WithEvents btnls3 As Button
End Class
