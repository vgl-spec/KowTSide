Imports System.Drawing
Imports System.Drawing.Drawing2D
Imports System.Windows.Forms

Public Class RoundedButton
    Inherits Button

    Public Property BorderRadius As Integer = 20
    Public Property FillColor As Color = Color.LightGreen
    Public Property TextColor As Color = Color.Black


    Public Sub New()
        Me.SetStyle(ControlStyles.AllPaintingInWmPaint Or
                    ControlStyles.UserPaint Or
                    ControlStyles.OptimizedDoubleBuffer, True)
        Me.FlatStyle = FlatStyle.Flat
        Me.FlatAppearance.BorderSize = 0
        Me.BackColor = Color.Transparent
    End Sub

    Protected Overrides Sub OnPaint(pevent As PaintEventArgs)
        MyBase.OnPaint(pevent)
        Dim g = pevent.Graphics
        g.SmoothingMode = SmoothingMode.AntiAlias

        Dim rect As New Rectangle(0, 0, Me.Width, Me.Height)
        Using path As GraphicsPath = GetRoundedRectPath(rect, BorderRadius)
            Using brush As New SolidBrush(FillColor)
                g.FillPath(brush, path)
            End Using
            Using borderPen As New Pen(Color.FromArgb(100, FillColor), 1)
                g.DrawPath(borderPen, path)
            End Using
        End Using

        Dim textRect As New Rectangle(5, 5, Me.Width - 10, Me.Height - 10)
        TextRenderer.DrawText(g, Me.Text, Me.Font, textRect, TextColor,
                              TextFormatFlags.HorizontalCenter Or TextFormatFlags.VerticalCenter)
    End Sub

    Private Function GetRoundedRectPath(rect As Rectangle, radius As Integer) As GraphicsPath
        Dim d = radius * 2
        Dim path As New GraphicsPath()
        path.StartFigure()
        path.AddArc(rect.X, rect.Y, d, d, 180, 90)
        path.AddArc(rect.Right - d, rect.Y, d, d, 270, 90)
        path.AddArc(rect.Right - d, rect.Bottom - d, d, d, 0, 90)
        path.AddArc(rect.X, rect.Bottom - d, d, d, 90, 90)
        path.CloseFigure()
        Return path
    End Function
End Class
