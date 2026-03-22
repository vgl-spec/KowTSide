Imports System.Drawing
Imports System.Drawing.Drawing2D
Imports System.Windows.Forms

Public Class RoundedTextBox
    Inherits UserControl

    Private innerTextBox As TextBox
    Private eyeButton As Button
    Private _borderRadius As Integer = 15
    Private _placeholderText As String = "Enter text..."
    Private _placeholderColor As Color = Color.Gray
    Private _borderColor As Color = Color.DarkGray
    Private _fillColor As Color = Color.White
    Private _isPassword As Boolean = False
    Private _showPassword As Boolean = False

    Public Property BorderRadius As Integer
        Get
            Return _borderRadius
        End Get
        Set(value As Integer)
            _borderRadius = value
            Me.Invalidate()
        End Set
    End Property

    Public Property PlaceholderText As String
        Get
            Return _placeholderText
        End Get
        Set(value As String)
            _placeholderText = value
            Me.Invalidate()
        End Set
    End Property

    Public Property IsPassword As Boolean
        Get
            Return _isPassword
        End Get
        Set(value As Boolean)
            _isPassword = value
            innerTextBox.UseSystemPasswordChar = _isPassword AndAlso Not _showPassword
            eyeButton.Visible = _isPassword
        End Set
    End Property

    Public ReadOnly Property TextBox As TextBox
        Get
            Return innerTextBox
        End Get
    End Property

    Public Sub New()
        Me.DoubleBuffered = True

        innerTextBox = New TextBox()
        innerTextBox.BorderStyle = BorderStyle.None
        innerTextBox.Location = New Point(10, 7)
        innerTextBox.Width = Me.Width - 40
        innerTextBox.Anchor = AnchorStyles.Top Or AnchorStyles.Left Or AnchorStyles.Right
        AddHandler innerTextBox.TextChanged, AddressOf InnerTextChanged
        Me.Controls.Add(innerTextBox)

        eyeButton = New Button()
        eyeButton.Text = "👁" ' simple eye icon using emoji
        eyeButton.Font = New Font("Segoe UI Emoji", 10)
        eyeButton.Size = New Size(30, 25)
        eyeButton.Location = New Point(Me.Width - 35, 7)
        eyeButton.Anchor = AnchorStyles.Top Or AnchorStyles.Right
        eyeButton.FlatStyle = FlatStyle.Flat
        eyeButton.FlatAppearance.BorderSize = 0
        eyeButton.Visible = False
        AddHandler eyeButton.Click, AddressOf TogglePassword
        Me.Controls.Add(eyeButton)
    End Sub

    Protected Overrides Sub OnPaint(e As PaintEventArgs)
        MyBase.OnPaint(e)
        Dim g = e.Graphics
        g.SmoothingMode = SmoothingMode.AntiAlias

        Dim rect As New Rectangle(0, 0, Me.Width - 1, Me.Height - 1)
        Using path As GraphicsPath = GetRoundedRectPath(rect, _borderRadius)
            Using brush As New SolidBrush(_fillColor)
                g.FillPath(brush, path)
            End Using
            Using pen As New Pen(_borderColor, 1)
                g.DrawPath(pen, path)
            End Using
        End Using

        If String.IsNullOrEmpty(innerTextBox.Text) Then
            TextRenderer.DrawText(g, _placeholderText, innerTextBox.Font,
                                  innerTextBox.Bounds, _placeholderColor,
                                  TextFormatFlags.VerticalCenter Or TextFormatFlags.Left)
        End If
    End Sub

    Private Function GetRoundedRectPath(rect As Rectangle, radius As Integer) As GraphicsPath
        Dim path As New GraphicsPath()
        Dim d = radius * 2
        path.StartFigure()
        path.AddArc(rect.X, rect.Y, d, d, 180, 90)
        path.AddArc(rect.Right - d, rect.Y, d, d, 270, 90)
        path.AddArc(rect.Right - d, rect.Bottom - d, d, d, 0, 90)
        path.AddArc(rect.X, rect.Bottom - d, d, d, 90, 90)
        path.CloseFigure()
        Return path
    End Function

    Private Sub InnerTextChanged(sender As Object, e As EventArgs)
        Me.Invalidate()
    End Sub

    Private Sub TogglePassword(sender As Object, e As EventArgs)
        _showPassword = Not _showPassword
        innerTextBox.UseSystemPasswordChar = _isPassword AndAlso Not _showPassword
    End Sub
End Class
