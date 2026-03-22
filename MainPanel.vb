Imports System.Drawing.Drawing2D

Public Class MainPanel




    Private Sub FlowLayoutPanel1_Paint(sender As Object, e As PaintEventArgs) Handles FlowLayoutPanel1.Paint
        Dim g As Graphics = e.Graphics
        g.SmoothingMode = SmoothingMode.AntiAlias

        Dim borderColor As Color = Color.Brown
        Dim borderThickness As Integer = 3
        Dim radius As Integer = 20

        Dim rect As New Rectangle(1, 1, FlowLayoutPanel1.Width - 3, FlowLayoutPanel1.Height - 3)

        Using path As New GraphicsPath()
            path.AddArc(rect.X, rect.Y, radius, radius, 180, 90)
            path.AddArc(rect.Right - radius, rect.Y, radius, radius, 270, 90)
            path.AddArc(rect.Right - radius, rect.Bottom - radius, radius, radius, 0, 90)
            path.AddArc(rect.X, rect.Bottom - radius, radius, radius, 90, 90)
            path.CloseFigure()

            Using pen As New Pen(borderColor, borderThickness)
                pen.Alignment = PenAlignment.Inset
                g.DrawPath(pen, path)
            End Using
        End Using
    End Sub

    Private Sub MainPanel_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        signoutbtn.Font = New Font(CustomFont, 22)
        signoutbtn.ForeColor = Color.White
        welcome.Font = New Font(CustomFont, 76)
        welcome.ForeColor = Color.Yellow
        btnls1.Font = New Font(CustomFont, 20)
        btnls2.Font = New Font(CustomFont, 20)
        btnls3.Font = New Font(CustomFont, 20)

        FlowLayoutPanel1.Controls.Add(CreateFinalCard("Lapid, Jaycee P.", "Barangay San Agustin"))
    End Sub

    Private Function CreateFinalCard(name As String, barangay As String) As Panel
        Dim card As New Panel With {
            .Width = 1100,
            .Height = 150,
            .BackColor = Color.White,
            .Margin = New Padding(10),
            .BorderStyle = BorderStyle.FixedSingle
        }


        Dim lblName As New Label With {
            .Text = name,
            .Font = New Font(CustomFont, 30, FontStyle.Bold),
            .ForeColor = Color.Black,
            .Location = New Point(25, 25),
            .AutoSize = True
        }

        Dim lblBarangay As New Label With {
            .Text = barangay,
            .Font = New Font(CustomFont, 18),
            .ForeColor = Color.DimGray,
            .Location = New Point(28, 75),
            .AutoSize = True
        }

        card.Controls.Add(lblName)
        card.Controls.Add(lblBarangay)


        Dim btnOptions As New Button With {
            .Text = "⋮",
            .Tag = name,
            .Size = New Size(35, 30),
            .Location = New Point(card.Width - 50, 15),
            .FlatStyle = FlatStyle.Flat,
            .BackColor = Color.Gainsboro
        }
        btnOptions.FlatAppearance.BorderSize = 0

        AddHandler btnOptions.Click, AddressOf ShowProfileOptions
        card.Controls.Add(btnOptions)


        Dim subjects() As String = {"MATH", "ENGLISH"}
        Dim startY As Integer = 35

        For i As Integer = 0 To subjects.Length - 1
            Dim y As Integer = startY + (i * 55)

            Dim lblSubject As New Label With {
                .Text = subjects(i),
                .Font = New Font(CustomFont, 20, FontStyle.Bold),
                .ForeColor = Color.DarkGreen,
                .Location = New Point(500, y),
                .AutoSize = True
            }

            Dim lblEasy As New Label With {
                .Text = "EASY:",
                .Font = New Font(CustomFont, 14),
                .Location = New Point(620, y),
                .AutoSize = True
            }

            Dim lblAve As New Label With {
                .Text = "AVE:",
                .Font = New Font(CustomFont, 14),
                .Location = New Point(760, y),
                .AutoSize = True
            }

            Dim lblDiff As New Label With {
                .Text = "DIFF:",
                .Font = New Font(CustomFont, 14),
                .Location = New Point(900, y),
                .AutoSize = True
            }

            card.Controls.Add(lblSubject)
            card.Controls.Add(lblEasy)
            card.Controls.Add(lblAve)
            card.Controls.Add(lblDiff)
        Next

        Return card
    End Function

    Private Sub ShowProfileOptions(sender As Object, e As EventArgs)
        Dim btn As Button = CType(sender, Button)
        Dim studentName As String = btn.Tag.ToString()

        Dim menu As New ContextMenuStrip()
        menu.Items.Add("Remove", Nothing, Sub() btn.Parent.Dispose())
        menu.Items.Add("Cancel")

        menu.Show(btn, New Point(0, btn.Height))
    End Sub

    Private Sub signoutbtn_Click(sender As Object, e As EventArgs) Handles signoutbtn.Click
        Me.Hide()
        Login.Show()

    End Sub
End Class