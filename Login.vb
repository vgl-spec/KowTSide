Public Class Login
    Private Sub Login_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        LoadGlobalFont()


        Label1.Font = New Font(CustomFont, 48)
        Label1.ForeColor = Color.Yellow
        BtnLogin.Font = New Font(CustomFont, 16)
        emaillbl.Font = New Font(CustomFont, 16)
        passlbl.Font = New Font(CustomFont, 16)

        passtxtbox.Font = New Font(CustomFont, 20)




    End Sub


    Private Sub btnClose_Click(sender As Object, e As EventArgs) Handles btnClose.Click
        Me.Close()

    End Sub

    Private Sub passtxtbox_Paint(sender As Object, e As PaintEventArgs)

    End Sub

    Private Sub BtnLogin_Click(sender As Object, e As EventArgs) Handles BtnLogin.Click
        Me.Hide()
        MainPanel.Show()

    End Sub
End Class
