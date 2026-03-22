Imports System.Drawing.Text
Imports System.Runtime.InteropServices

Module GlobalFont
    Public pfc As New PrivateFontCollection()


    Public Sub LoadGlobalFont()
        Dim fontBytes As Byte() = My.Resources.Super_Cartoon
        Dim ptr As IntPtr = Marshal.AllocCoTaskMem(fontBytes.Length)
        Marshal.Copy(fontBytes, 0, ptr, fontBytes.Length)
        pfc.AddMemoryFont(ptr, fontBytes.Length)
        Marshal.FreeCoTaskMem(ptr)
    End Sub


    Public ReadOnly Property CustomFont As FontFamily
        Get
            Return pfc.Families(0)
        End Get
    End Property
End Module
