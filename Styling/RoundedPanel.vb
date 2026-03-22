Imports System.Drawing.Drawing2D

Public Class RoundedPanel
    Inherits Panel

    Public Property BorderRadius As Integer = 20

    Protected Overrides Sub OnPaint(e As PaintEventArgs)
        MyBase.OnPaint(e)

        e.Graphics.SmoothingMode = SmoothingMode.AntiAlias

        Dim path As New GraphicsPath()
        Dim d As Integer = BorderRadius * 2
        path.StartFigure()
        path.AddArc(0, 0, d, d, 180, 90)
        path.AddArc(Me.Width - d, 0, d, d, 270, 90)
        path.AddArc(Me.Width - d, Me.Height - d, d, d, 0, 90)
        path.AddArc(0, Me.Height - d, d, d, 90, 90)
        path.CloseFigure()

        Me.Region = New Region(path)
    End Sub
End Class
