VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "HZ2PY"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'***************************************************************************
'*
'* Module:          HzToPy
'* Update:          2011-09-23
'* Author:          tt.t
'*
'* Description:     �������ַ���ת��Ϊƴ��������Щ��ԭ������д��̫��ϻ���ɾ�ˡ�
'*
'* Theory��         ԭ����Ȼ��ͨ��IFELanguage�ӿ�ʵ�֡�
'*                  Ψһ��Ҫ���͵�����ν����������ȷע�������⡣
'*                  IFELanguage�ӿ����ܹ���ȷ���غܶ������ƴ���ģ��������ֵĶ���ֻ���ض��ʻ���
'*                  ����ȷ�ϣ�����ڽ���ƴ��ʱ���ܰѴʲ�ɵ��֣���������ַ��ص�ƴ���ͺܿ��ܲ��ԡ�
'*                  ֮ǰ�汾�о�����Ϊ�Ѵʲ𿪻�ȡƴ�����¶�����ƴ������
'*                  ��εĸ������ýӿڷ��������б�ʶÿ��ƴ�����ȵ�����ʵ���˶Է���ƴ��
'*                  �İ��ֲ�֣������ٰѴʲ���ֻ�ȡ�����ֵ�ƴ�����Ӷ�����˶��������⡣
'*                  ��Ҫ˵�����ǣ�VB_MORRSLT�ṹ����MS�ĵ��е�MORRSLT�ṹ������VBA�Զ���ṹ
'*                  �޷�ʵ�ֲ���4�ֽڶ��룬ʹ�ò��ò��޸�MORRSLT�Ķ��巽ʽ���������޸�ֻ��˵����������
'*                  ��Ϊ���޸ĵĲ��ָպû�ȡƴ���ò�����
'*
'*
'* Histroy:
'*                  2011-09-23
'*                  �� ��д��Ҫ���룬֧�ֶ����֣����������Ч�ʡ�
'*                  �� ȡƴ������ʱ��ao, ai, ei, ou, er��Ϊ���ֶ�����ԭ���ĵ�һ����ĸ��
'*                  �� Ϊ����������ע����ʽѡ��h��n������ʾΪhan��han4��
'*                  �� ������ʹ����֮ǰ�汾���ݣ���ģ���к��������HZ2PY����븲��֮ǰ�汾����ʵ�������������޸��ĵ��еĹ�ʽ��
'*                  2011-04-07
'*                  �� ����CoTaskMemFree���ݲ�������������Win7�Ȼ����±�����
'*                  2007-04-03
'*                  �� ����redimʱvba����Ĭ����ʼֵ����
'*                  2007-04-02
'*                  �� ����汾��ʵ�����ɺ��ֻ�ȡƴ����
'*
'***************************************************************************

Option Explicit

Private Type GUID
    Data1 As Long
    Data2 As Integer
    Data3 As Integer
    Data4(0 To 7) As Byte
End Type

Private Type VB_MORRSLT
    dwSize As Long          '4
    pwchOutput As Long      '4
    cchOutput As Integer    '2+(2)��VBA�ڴ�����ֵã������˺�һ���ȷ���������ڣ���
    Block1 As Long          '4
    pchInputPos As Long     '4
    pchOutputIdxWDD As Long '4
    pchReadIdxWDD As Long   '4
    paMonoRubyPos As Long   '4
    pWDD As Long            '4
    cWDD As Integer         '2
    pPrivate As Long        '4
    BLKBuff As Long         '4
End Type

Private Declare Sub MoveMemory Lib "kernel32" Alias "RtlMoveMemory" _
        (Destination As Any, Source As Any, ByVal Length As Long)
        
Private Declare Function CLSIDFromString Lib "ole32.dll" _
        (ByVal lpszProgID As Long, pCLSID As GUID) As Long
        
Private Declare Function CoCreateInstance Lib "ole32" ( _
        rclsid As GUID, ByVal pUnkOuter As Long, _
        ByVal dwClsContext As Long, riid As GUID, _
        ByRef ppv As Long) As Long

Private Declare Function DispCallFunc Lib "oleaut32" _
        (ByVal pvInstance As Long, ByVal oVft As Long, _
        ByVal cc As Long, ByVal vtReturn As Integer, _
        ByVal cActuals As Long, prgvt As Integer, _
        prgpvarg As Long, pvargResult As Variant) As Long

Private Declare Sub CoTaskMemFree Lib "ole32" (pv As Long)

Dim MSIME_GUID As GUID          'MSIME's GUID
Dim IFELanguage_GUID As GUID    'IFELanguage's GUID
Dim IFELanguage As Long         'Pointer to IFELanguage interface
Dim PinYinArray() As String
Dim HzLen As Integer

Dim pvSeperator As String
Dim pvUseSeperator As Boolean
Dim pvInitialOnly As Boolean
Dim pvOnlyOneChar As Boolean
Dim pvNonChnUseSep As Boolean

Public Function GetPinYin(HzStr As String) As String
    Dim i As Integer
    Dim Py As String
    Dim IsPy As Boolean
    
    GetPinYin = ""
    If IFELanguage = 0 Then
        GetPinYin = "δ�������л������밲װ΢��ƴ��2.0���ϰ汾��"
        Exit Function
    End If
    If HzStr = "" Then Exit Function
    HzLen = Len(HzStr)
    Call IFELanguage_GetMorphResult(HzStr)
    For i = 1 To HzLen
        Py = PinYinArray(i)
        IsPy = Py <> ""
        If Not IsPy Then Py = Mid(HzStr, i, 1)
        If pvInitialOnly Then Py = GetInitial(Py)
        If pvOnlyOneChar Then Py = VBA.Left(Py, 1)
        GetPinYin = GetPinYin & Py & IIf(IsPy, pvSeperator, "")
    Next i
    If IsPy And pvSeperator <> "" Then GetPinYin = Left(GetPinYin, Len(GetPinYin) - 1)
End Function

Property Get Seperator() As String
    Seperator = pvSeperator
End Property

Property Let Seperator(Value As String)
    pvSeperator = Value
End Property

Property Get InitialOnly() As Boolean
    pvUseSeperator = pvInitialOnly
End Property

Property Let InitialOnly(Value As Boolean)
    pvInitialOnly = Value
End Property

Property Get OnlyOneChar() As Boolean
    pvUseSeperator = pvOnlyOneChar
End Property

Property Let OnlyOneChar(Value As Boolean)
    pvOnlyOneChar = Value
End Property

Public Function AdjustPhoneticNotation(Py As String, ByVal pn As Integer) As String
    Dim i As Integer
    Dim c As String
    
    If pn = -1 Then
        AdjustPhoneticNotation = Py
        Exit Function
    Else
        For i = 1 To Len(Py)
            c = VBA.Mid(Py, i, 1)
            Select Case Asc(c)
            Case VBA.Asc("��") To VBA.Asc("��")
                c = "a" & IIf(pn = 0, "", (VBA.Asc(c) - VBA.Asc("��") + 1))
            Case VBA.Asc("��") To VBA.Asc("��")
                c = "e" & IIf(pn = 0, "", (VBA.Asc(c) - VBA.Asc("��") + 1))
            Case VBA.Asc("��") To VBA.Asc("��")
                c = "i" & IIf(pn = 0, "", (VBA.Asc(c) - VBA.Asc("��") + 1))
            Case VBA.Asc("��") To VBA.Asc("��")
                c = "o" & IIf(pn = 0, "", (VBA.Asc(c) - VBA.Asc("��") + 1))
            Case VBA.Asc("��") To VBA.Asc("��")
                c = "u" & IIf(pn = 0, "", (VBA.Asc(c) - VBA.Asc("��") + 1))
            Case VBA.Asc("��") To VBA.Asc("��")
                c = "u" & IIf(pn = 0, "", (VBA.Asc(c) - VBA.Asc("��") + 1))
            Case VBA.Asc("��")
                c = "u"
            Case VBA.Asc("��")
                c = "g"
            End Select
            AdjustPhoneticNotation = AdjustPhoneticNotation & c
        Next i
    End If
End Function

Private Function GetInitial(Py As String) As String
    GetInitial = VBA.Mid(Py, 1, 2)
    Select Case AdjustPhoneticNotation(GetInitial, 0)
    Case "ch", "sh", "zh", "ao", "ai", "ei", "ou", "er"
    Case Else
        GetInitial = VBA.Left(GetInitial, 1)
    End Select
End Function

Private Function IFELanguage_GetMorphResult(HzStr As String) As String
    Dim ret As Variant
    Dim pArgs(0 To 5) As Long
    Dim vt(0 To 5) As Integer
    Dim Args(0 To 5) As Long
    Dim ResultPtr As Long
    Dim TinyM As VB_MORRSLT
    Dim Py() As Byte
    Dim i As Integer
    Dim j As Integer
    Dim PinyinIndexArray() As Integer
        
    IFELanguage_GetMorphResult = ""
    If IFELanguage = 0 Then Exit Function
    
    Args(0) = &H30000
    Args(1) = &H40000100
    Args(2) = Len(HzStr)
    Args(3) = StrPtr(HzStr)
    Args(4) = 0
    Args(5) = VarPtr(ResultPtr)
        
    For i = 0 To 5
        vt(i) = vbLong
        pArgs(i) = VarPtr(Args(i)) - 8
    Next
    
    Call DispCallFunc(IFELanguage, 20, 4, vbLong, 6, vt(0), pArgs(0), ret)
    Call MoveMemory(TinyM, ByVal ResultPtr, Len(TinyM))

    ReDim PinyinIndexArray(0 To HzLen - 1)
    ReDim PinYinArray(1 To HzLen)
    If TinyM.cchOutput > 0 Then
        ReDim Py(0 To TinyM.cchOutput * 2 - 1)
        Call MoveMemory(Py(0), ByVal TinyM.pwchOutput, TinyM.cchOutput * 2)
        IFELanguage_GetMorphResult = Py
        Call MoveMemory(PinyinIndexArray(0), ByVal TinyM.paMonoRubyPos + 2, HzLen * 2)
        j = 0
        For i = 0 To HzLen - 1
            PinYinArray(i + 1) = VBA.Mid(IFELanguage_GetMorphResult, j + 1, PinyinIndexArray(i) - j)
            j = PinyinIndexArray(i)
        Next i
    End If
    
    Call CoTaskMemFree(ByVal ResultPtr)
End Function

Private Sub IFELanguage_Open()
    Dim ret As Variant
    
    Call DispCallFunc(IFELanguage, 4, 4, vbLong, 0, 0, 0, ret)
    Call DispCallFunc(IFELanguage, 12, 4, vbLong, 0, 0, 0, ret)
End Sub

Private Sub IFELanguage_Close()
    Dim ret As Variant
    
    If IFELanguage = 0 Then Exit Sub
    Call DispCallFunc(IFELanguage, 8, 4, vbLong, 0, 0, 0, ret)
    Call DispCallFunc(IFELanguage, 16, 4, vbLong, 0, 0, 0, ret)
End Sub

Private Function GenerateGUID()
    Dim Rlt As Long
    
    'MSIME.China GUID = "{E4288337-873B-11D1-BAA0-00AA00BBB8C0}"
    Rlt = CLSIDFromString(StrPtr("MSIME.China"), MSIME_GUID)
    'IFELanguage GUID = "{019F7152-E6DB-11d0-83C3-00C04FDDB82E}"
    With IFELanguage_GUID
        .Data1 = &H19F7152
        .Data2 = &HE6DB
        .Data3 = &H11D0
        .Data4(0) = &H83
        .Data4(1) = &HC3
        .Data4(2) = &H0
        .Data4(3) = &HC0
        .Data4(4) = &H4F
        .Data4(5) = &HDD
        .Data4(6) = &HB8
        .Data4(7) = &H2E
    End With
    GenerateGUID = Rlt = 0
End Function

Private Sub Class_Initialize()
    IFELanguage = 0
    pvSeperator = ""
    GenerateGUID
    If CoCreateInstance(MSIME_GUID, 0, 1, IFELanguage_GUID, IFELanguage) = 0 Then Call IFELanguage_Open
End Sub

Private Sub Class_Terminate()
    If IFELanguage <> 0 Then Call IFELanguage_Close
End Sub