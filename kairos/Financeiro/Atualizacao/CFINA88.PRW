
/*
Função    : CFINA88
Objetivo  : Tracker Kairos para rastreabilidade a partir do Contas a Receber
Parametro : Nil
Retorno   : Nil
Autor     : Alexsander Martins dos Santos
Data      : 06/12/2019 
Empresa   : CIEE
teste gitlab merge
*/

#Include "TOTVS.ch"
#Include "DBTREE.ch"
#Include 'FWMVCDEF.ch'
#Include "TOPCONN.ch"

User Function CFINA88()

Local aGetArea    := GetArea()
Local aGetAreaSE1 := SE1->(GetArea())
Local aGetAreaZC5 := ZC5->(GetArea())
Local aGetAreaZC1 := ZC1->(GetArea()) 
Local aGetAreaZC4 := ZC4->(GetArea()) 
Local aGetAreaZC3 := ZC3->(GetArea())
Local aGetAreaZC6 := ZC6->(GetArea())
Local aGetAreaZC2 := ZC2->(GetArea())
Local aGetAreaSC5 := SC5->(GetArea())
Local aGetAreaSF2 := SF2->(GetArea()) 
Local aGetAreaSD2 := SD2->(GetArea())


Begin Sequence

   If Alltrim(SE1->E1_TIPO) <> "PR" .And. ! CFINA88Check()   //Não Consiste para Provisórios
      Break
   EndIf

   CFINA88Dialog()

End Sequence

RestArea(aGetAreaSD2)
RestArea(aGetAreaSF2)
RestArea(aGetAreaSC5)
RestArea(aGetAreaZC2)
RestArea(aGetAreaZC3) 
RestArea(aGetAreaZC6)
RestArea(aGetAreaZC4)
RestArea(aGetAreaZC1)
RestArea(aGetAreaZC5)
RestArea(aGetAreaSE1)
RestArea(aGetArea)

Return(Nil)


/*
Função    : CFINA88Check
Objetivo  : Checa a existencia e a integridade da rastreabilidade/relacionamento.
Parametro : Nil
Retorno   : .T. - Rastreabilidade ok.
            .F. - Rastreabilidade not ok.
Autor     : Alexsander Martins dos Santos
Data      : 06/12/2019
Empresa   : CIEE
*/

Static Function CFINA88Check()

Local lRet := .F.

Begin Sequence

   //Consiste se o Título a Receber possui o Identificador de Rastreabilidade.
   //Consiste a existencia do Registro da Fatura (ZC5).
   If !Empty(SE1->E1_XIDFATU)
      DBSELECTAREA("ZC1")
      DBclosearea()

      DBSELECTAREA("ZC3")
      DBclosearea()

      DBSELECTAREA("ZC4")
      DBclosearea()

      DBSELECTAREA("ZC5")
      DBclosearea()

   	if select("Z93")>0
   		Z93->(DBCLOSEAREA())
	   endif


      ZC5->(dbSetOrder(8))
      ZC5->(dbSeek(SE1->E1_XIDFATU))
      If !ZC5->(Found())
         MsgAlert("Não foi econtrado o Registro da Fatura correspondente ao ID: "+RTrim(SE1->E1_XIDFATU)+" que se encontra no Título a Receber.", "Atenção")
         Break
      EndIf
   Endif

   IF Empty(SE1->E1_XIDCNT) // SE1->E1_XIDLOC
      MsgInfo("Título a Receber sem declaração de Contrato.", "Atenção")
      Break
   EndIf

   lRet := .T. 

End Sequence

Return(lRet)


/*
Função    : CFINA88Dialog
Objetivo  : MSDialog do Tracker Kairos do Contas a Receber
Parametro : Nil
Retorno   : Nil
Autor     : Alexsander Martins dos Santos
Data      : 06/12/2019
Empresa   : CIEE
*/

Static Function CFINA88Dialog()

Local oDlg
Local aSize, aObjects, aInfo, aPosObj
Local aCoors:= FWGetDialogSize(oMainWnd)	//{0,0,550,1300} 
//Local aCoors:= {0,0,550,1300} 

Local bOk      := {|| oDlg:End()}
Local bCancel  := {|| oDlg:End()}

Local aButtons := {{"BMPVISUAL", {|| CFINA88TView(@oTree)},  "Visualizar"}}

Local oTree
Local oPanelTree
Local oPanelView
Local oMsMGet:= ""

Local oMsGetDados:=""

Private aHeader := {}
Private aCols	:= {}
Private lexist:= .T.
Private cFileTRB  := ""
Private cAliasTRB := ""

Private cCodIDFOLHA:= ""
Private cCodIDFatur:= ""
Private cCodIDCobra:= ""

Begin Sequence

   /*
   Definicao das coordenadas para os objetos visuais.
   */
   aSize    := MsAdvSize()
  // aSize    := FwDefSize():New(.T.)
/*
   aObjects := {{ 100, 060, .T., .F. },;
                { 100, 100, .T., .T. }}

*/

   aObjects := {{ 100, 060, .T., .F. },;
                { 100, 100, .T., .T. }}




   aInfo    := { aSize[1],;
                 aSize[2],;
                 aSize[3],;
                 aSize[4],;
                 2,;
                 2 }

   aPosObj  := MsObjSize(aInfo, aObjects)


   //Define MsDialog oDlg Title "Tracker Kairos" From aSize[7], 0 To aSize[6], aSize[5] Of oMainWnd Pixel
   Define MsDialog oDlg Title "Tracker Kairos" +  If(Alltrim(SE1->E1_TIPO) = "PR"," - PROVISÓRIO","") From aCoors[1], aCoors[2] To aCoors[3], aCoors[4] Pixel

      aSizeT := FwDefSize():New(.T.)
   if aSizeT:AWINDSIZE[3] > 600
      @ 033, 003 MSPanel oPanelTree Prompt "Kairos Tipo: "  + Alltrim(SE1->E1_TIPO) Colors CLR_BLACK,CLR_WHITE LOWERED RAISED Size 150, 418 Of oDlg
//      @ 033, 156 MSPanel oPanelView Prompt "View Tipo: "    + Alltrim(SE1->E1_TIPO) Colors CLR_BLACK,CLR_WHITE LOWERED RAISED Size 903, 633 Of oDlg
      @ 033, 156 MSPanel oPanelView Prompt "View Tipo: "    + Alltrim(SE1->E1_TIPO) Colors CLR_BLACK,CLR_WHITE LOWERED RAISED Size 789, 633 Of oDlg
   else
//original
      @ 033, 003 MSPanel oPanelTree Prompt "Kairos Tipo: "  + Alltrim(SE1->E1_TIPO) Colors CLR_BLACK,CLR_WHITE LOWERED RAISED Size 200, 263 Of oDlg
      @ 033, 156 MSPanel oPanelView Prompt "View Tipo: "    + Alltrim(SE1->E1_TIPO) Colors CLR_BLACK,CLR_WHITE LOWERED RAISED Size 516, 263 Of oDlg
   endif


//   oTree := dbTree():New(010, 005, 260, 200, oPanelTree,,, .T., .F.,, "Tracker__")
   oTree := dbTree():New(010, 005, 415, 150, oPanelTree,,, .T., .F.,, "Tracker")


   oTree:lShowHint := .T.
   oTree:bChange   := {|| CFINA88TChange(@oTree, @oPanelView, @oMsMGet, @oMsGetDados)}

   Processa({|| CFINA88TLoad(@oTree)}, "Aguarde", "Carregando o Tracking para título tipo: " + Alltrim(SE1->E1_TIPO) , .F.)

   MsAguarde({|| CFINA88TChange(@oTree, @oPanelView, @oMsMGet, @oMsGetDados)}, "Aguarde", "Carregando o Título a Receber", .F.)

   Activate MsDialog oDlg On Init EnchoiceBar(oDlg, bOk, bCancel,, aButtons) Centered



   Release Object oTree

   If !Empty(cAliasTRB) .And. Select(cAliasTRB) > 0
      DBSelectArea(cAliasTRB)
      DBCloseArea()
      FErase(AllTrim(cFileTRB)+GetDBExtension())
      FErase(AllTrim(cFileTRB+"A")+OrdBagExt()) 		
   EndIf

End Sequence

Return(Nil)


/*
Função    : CFINA88TLoad
Objetivo  : Carrega a arvore com a rastreabilidade.
Parametro : oTree : Objeto Tree.
Retorno   : Nil
Autor     : Alexsander Martins dos Santos
Data      : 06/12/2019
Empresa   : CIEE
*/

Static Function CFINA88TLoad(oTree)

Local aPedidos    := {}
Local nPos        := 0
Local cSQL     
Local cXquery:= ""

Begin Sequence

   oTree:BeginUpdate()
   oTree:Reset()
   oTree:TreeSeek("")

   ProcRegua(9)   // Processamento com 9 Tracking 

   /*
   Track 1
   Adiciona o Título a Receber - SE1
   */
   oTree:AddItem("Título a Receber: "+RTrim(SE1->E1_NUM)+" | Prefixo: "+RTrim(SE1->E1_PREFIXO), "SE1"+LTrim(Str(SE1->(Recno()))), "FOLDER10", "FOLDER11",,, 1)

   IncProc()

   /*
   Track 2
   Posiciona no Registro da Fatura - ZC5
   */
   ZC1->(dbSetOrder(1))
   
   If Alltrim(SE1->E1_TIPO) <> "PR"  .And. !Empty(SE1->E1_XIDFATU)
//      cXalias:= "ZC5"
      cXalias:= "ZC1"
      ZC1->(dbSeek(xFilial("ZC1")+ZC5->ZC5_IDCONT+ZC5->ZC5_LOCCON))       
   else
      ZC1->(dbSeek(xFilial("ZC1")+SE1->E1_XIDCNT + SE1->E1_XIDLOC))  //Posiciona no Locais de Contratos
      cXalias:= "ZC1" 
   ENDIF
   
   If ZC1->(Found())
      oTree:AddItem("Contrato: "+RTrim(SE1->E1_XIDCNT)+" | Local: "+RTrim(SE1->E1_XIDLOC), cXalias+LTrim(Str(ZC1->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
   Else
      oTree:AddItem("Contrato: "+RTrim(SE1->E1_XIDCNT)+" | Local: "+RTrim(SE1->E1_XIDLOC), cXalias+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
   EndIf

   IncProc()

   /*
   Track 3
   Localiza a Configuração do Faturamento - ZC4
   */
   ZC4->(dbSetOrder(1))    
   If Alltrim(SE1->E1_TIPO) <> "PR" 
      //Consiste se o Título a Receber possui o Identificador de Rastreabilidade.
      If Empty(SE1->E1_XIDFATU)
         oTree:AddItem("Configuração da Fatura: ", "ZC4"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)   
      Else
         ZC4->(dbSeek(xFilial("ZC4")+ZC5->ZC5_CONFAT+ZC5->ZC5_IDCONT))
         If ZC4->(Found())
            oTree:AddItem("Configuração da Fatura: "+RTrim(SE1->E1_XIDFATU), "ZC4"+LTrim(Str(ZC4->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
         Else
            oTree:AddItem("Configuração da Fatura: "+RTrim(SE1->E1_XIDFATU), "ZC4"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
         EndIf
      Endif

   ELSE
      cXquery:=" SELECT ZC4.R_E_C_N_O_ AS RECNOZC4"
      cXquery+=" FROM " + RetSqlName("ZC4") + " ZC4" 
      cXquery+=" WHERE ZC4_FILIAL ='" + xFilial("ZC4") + "'"
      cXquery+=" AND ZC4.D_E_L_E_T_=''"
      cXquery+=" AND ZC4_IDCONT = '" + SE1->E1_XIDCNT + "'"
      cXquery+=" AND ZC4_STATUS = '1' "

      IF SELECT("TMP") > 0
         TMP->(dbCloseArea())
      Endif 
                  
      TCQUERY cXQuery NEW ALIAS TMP  
                  
      If TMP->(!Eof()) .AND. !Empty(TMP->RECNOZC4)
         ZC4->(DBGOTO( TMP->RECNOZC4 ))
         oTree:AddItem("Configuração da Fatura: "+RTrim(SE1->E1_XIDFATU), "ZC4P"+LTrim(Str(ZC4->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
      ELSE
         oTree:AddItem("Configuração da Fatura: "+RTrim(SE1->E1_XIDFATU), "ZC4P"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      ENDIF

      TMP->(dbCloseArea())

   ENDIF

   cCodIDFatur:= RTrim(SE1->E1_XIDFATU)

   IncProc()

   /*
   Track 5
   Configuração da Cobraça - ZC3
   */
   ZC3->(dbSetOrder(1))

   If Alltrim(SE1->E1_TIPO) <> "PR" 
      If !Empty(SE1->E1_XIDFATU)
         ZC3->(dbSeek(xFilial("ZC3")+ZC5->ZC5_CONCOB+ZC5->ZC5_IDCONT+ZC5->ZC5_CONFAT))
         If ZC3->(Found())
            oTree:AddItem("Configuração da Cobrança: "+RTrim(ZC5->ZC5_CONCOB), "ZC3"+LTrim(Str(ZC3->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
         Else
            oTree:AddItem("Configuração da Cobrança: "+RTrim(ZC5->ZC5_CONCOB), "ZC3"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
         EndIf
         cCodIDCobra:= RTrim(ZC5->ZC5_CONCOB)
      else
         oTree:AddItem("Configuração da Cobrança: ", "ZC3"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      Endif
   ELSE
      cXquery:=" SELECT ZC3.R_E_C_N_O_ AS RECNOZC3"
      cXquery+=" FROM " + RetSqlName("ZC3") + " ZC3" 
      cXquery+=" WHERE ZC3_FILIAL ='" + xFilial("ZC3") + "'"
      cXquery+=" AND ZC3.D_E_L_E_T_=''"
      cXquery+=" AND ZC3_IDCONT = '" + SE1->E1_XIDCNT + "'"
      cXquery+=" AND ZC3_STATUS = '1' "
//33333
      IF SELECT("TMP") > 0
         TMP->(dbCloseArea())
      Endif 
                  
      TCQUERY cXQuery NEW ALIAS TMP  
                  
      If TMP->(!Eof()) .AND. !Empty(TMP->RECNOZC3)
         ZC3->(DBGOTO( TMP->RECNOZC3 ))
         oTree:AddItem("Configuração da Cobrança: "+RTrim(ZC3->ZC3_IDCOBR), "ZC3P"+LTrim(Str(ZC3->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
      ELSE
         oTree:AddItem("Cobrança do Contrato: "+RTrim(SE1->E1_XIDCNT), "ZC3P"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      ENDIF

      TMP->(dbCloseArea())

      cCodIDCobra:=  RTrim(ZC3->ZC3_IDCOBR)

   ENDIF

   IncProc()

   //Track Visão Analitica
   If Alltrim(SE1->E1_TIPO) == "PR" 
      SRA->(dbSetOrder(28))
      If !Empty(SE1->E1_XIDCNT) .And. SRA->(dbSeek(xFilial("SRA")+SE1->E1_XIDCNT + SE1->E1_XIDLOC))
         oTree:AddItem("Analitico: Provisórios", "SRA"+LTrim(Str(SRA->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
      ELSE
         oTree:AddItem("Analitico: Provisórios", "SRA"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      ENDIF

      ZC6->(dbSetOrder(03))
      If !Empty(SE1->E1_XIDCNT) .And. ZC6->(dbSeek(xFilial("ZC6")+SE1->E1_XIDCNT + SE1->E1_XIDLOC))
         oTree:AddItem("Analitico: Faturamentos", "ZC6"+LTrim(Str(ZC6->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
      ELSE
         oTree:AddItem("Analitico: Faturamentos", "ZC6"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      ENDIF
   ELSE
      ZC6->(dbSetOrder(04))
      If Empty(SE1->E1_XIDFATU)
         oTree:AddItem("Analitico: Faturamentos", "ZC6"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      Else
         //If ZC6->(dbSeek(xFilial("ZC6")+SE1->E1_XIDFATU))
         If ZC6->(dbSeek(SE1->E1_FILORIG+SE1->E1_XIDFATU))
            oTree:AddItem("Analitico: Faturamentos", "ZC6"+LTrim(Str(ZC6->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
         ELSE
            oTree:AddItem("Analitico: Faturamentos", "ZC6"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
         ENDIF
      Endif
/*      ZC5->(dbSetOrder(08))
      If Empty(SE1->E1_XIDFATU)
         oTree:AddItem("Analitico: Faturamentos", "ZC6"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      Else
         If ZC5->(dbSeek(SE1->E1_XIDFATU))
            oTree:AddItem("Analitico: Faturamentos", "ZC5"+LTrim(Str(ZC6->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
         ELSE
            oTree:AddItem("Analitico: Faturamentos", "ZC5"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
         ENDIF
      Endif      
*/
   ENDIF

   IncProc()

   /*
   Track 6
   Configuração da Folha - ZC6 e ZC2
   */
   If !Empty(SE1->E1_XIDFATU)
      cSQL := "SELECT "
      cSQL += "ZC6.ZC6_FILIAL AS ZC6_FILIAL, "
      cSQL += "ZC6.ZC6_LOTE AS ZC6_LOTE, "
      cSQL += "ZC6.ZC6_SEQLOT AS ZC6_SEQLOT, " 
      cSQL += "ZC6.ZC6_IDFOLH AS ZC6_IDFOLH "

      cSQL += "FROM "
      cSQL += RetSQLName("ZC6") + " as ZC6 "

      cSQL += "WHERE "
      cSQL += "ZC6.D_E_L_E_T_ <> '*' AND "
      cSQL += "ZC6.ZC6_IDFATU = '"+SE1->E1_XIDFATU+"'"

      TCQuery cSQL Alias "RecordSet" New

      RecordSet->(dbGoTop())

      ZC6->(dbSetOrder(1))
      ZC6->(dbSeek(RecordSet->(ZC6_LOTE+ZC6_SEQLOT)))

      ZC2->(dbSetOrder(1))
      ZC2->(dbSeek(xFilial("ZC2")+RecordSet->ZC6_IDFOLH))

      If ZC2->(Found())
         oTree:AddItem("Configuração da Folha: "+RTrim(ZC2->ZC2_IDFOLH), "ZC2"+LTrim(Str(ZC2->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
      Else
         oTree:AddItem("Configuração da Folha:", "ZC2"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      EndIf 

      RecordSet->(dbCloseArea())

      cCodIDFOLHA:= RTrim(ZC2->ZC2_IDFOLH)
   else
      oTree:AddItem("Configuração da Folha:", "ZC2"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)   
   Endif

   IncProc()

   If Alltrim(SE1->E1_TIPO) <> "PR" 
      /*
      Track 7
      Registro da Fatura - ZC5
      */
      If Empty(SE1->E1_XIDFATU)
         oTree:AddItem("Registro da Fatura:", "ZC5"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)  
      Else
         oTree:AddItem("Registro da Fatura: "+RTrim(ZC5->ZC5_IDFATU), "ZC5"+LTrim(Str(ZC5->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
      Endif

      IncProc()

      /*
      Track 8
      Pedidos de Venda - SC5 e SC6
      */
      SF2->(dbSetOrder(1))
      SF2->(dbSeek(xFilial("SF2")+ZC5->ZC5_NOTA+ZC5->ZC5_SERIE+ZC5->ZC5_CLIENT+ZC5->ZC5_LOJA))

      SD2->(dbSetOrder(3))
      SD2->(dbSeek(xFilial("SD2")+ZC5->ZC5_NOTA+ZC5->ZC5_SERIE+ZC5->ZC5_CLIENT+ZC5->ZC5_LOJA))

      While SD2->(!Eof() .and. D2_FILIAL == xFilial("SD2") .and. D2_DOC == ZC5->ZC5_NOTA .and. D2_SERIE == ZC5->ZC5_SERIE .and. D2_CLIENTE == ZC5->ZC5_CLIENTE .and. D2_LOJA == ZC5->ZC5_LOJA)

         If aScan(aPedidos, SD2->D2_PEDIDO) = 0
            aAdd(aPedidos, SD2->D2_PEDIDO)
         EndIf

         SD2->(dbSkip())

      End

      If Len(aPedidos) > 0

         SC5->(dbSetOrder(1))
         SC5->(dbSeek(xFilial("SC5")+aPedidos[1]))

         SC6->(dbSetOrder(1))
         SC6->(dbSeek(xFilial("SC6")+aPedidos[1]))

         For nPos := 1 To Len(aPedidos)
            oTree:AddItem("Pedido de Venda: "+aPedidos[nPos], "SC5"+LTrim(Str(SC5->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
         //     oTree:AddItem("Pedido de Venda: "+aPedidos[nPos], "SC5"+LTrim(Str(SC5->(Recno()))), , ,,, 1)
         Next

      Else

         oTree:AddItem("Pedido(s) de Venda: Não encontrado", "SC5"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)

      EndIf

      IncProc()

      /*
      Track 9
      Nota Fiscal - SF2 e SD2
      */
      If SF2->(Found())
         oTree:AddItem("Nota Fiscal: "+RTrim(ZC5->ZC5_NOTA)+" | Série: "+RTrim(ZC5->ZC5_SERIE), "SF2"+LTrim(Str(SF2->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
      Else
         oTree:AddItem("Nota Fiscal: "+RTrim(ZC5->ZC5_NOTA)+" | Série: "+RTrim(ZC5->ZC5_SERIE), "SF2"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      EndIf

      IncProc()

   ENDIF

   oTree:EndUpdate()
   oTree:Refresh()

End Sequence

Return(Nil)                           


/*
Função    : CFINA88TChange
Objetivo  : Função chamada na mudança de posição do item do Tree.
Parametro : oTree       : Objeto Tree.
            oPanelView  : Objeto Panel.
            oMsMGet     : Objeto MsMGet.
            oMsGetDados : Objeto oMsGetDados.
Retorno   : .T.
Autor     : Alexsander Martins dos Santos / Luiz Enrique
Data      : 06/12/2019
Empresa   : CIEE
*/

Static Function CFINA88TChange(oTree, oPanelView, oMsMGet, oMsGetDados)

Local cAlias
Local cSeek    
Local bWhile   
Local cAliasD  
Local nOrderD  
Local nRecno
Local lFound
Local oStruAlias
Local nPos
Local aAcho    := {}
Local aSize    := {}  
local aHeigt1  := {}
local nHeigUP1 := 0
local nHeiDow1 := 0

Local oFWLayer
Local oRelation
Local oRelatSra
Local oRelatSZ3
Local oRelatSZ4
Local oRelatSZ5
Local oRelatSZ6

Local oPanelUp
Local omBrowseUP
Local oPanelMeio
Local omBrowseMeio
Local oPanelDown
Local omBrowseDown

Private aCampos:={} 
Private Acolun1:={}
Private Acolun2:={}
Private Acolun3:={}


Private AcolZ93:= {}


//aAdd( AcolZ93 , { "FILIAL"             , "FILIAL"   , "C" , 04 , 0 , "@!" } ) 
//aAdd( AcolZ93 , { "CODIGO"             , "XID"      , "C" , 15 , 0 , "@!" } ) 
/*aAdd( AcolZ93 , { "NOME"               , "NOME"     , "C" , 30 , 0 , "@!" } ) 
aAdd( AcolZ93 , { "CPF"                , "CIC"      , "C" , 11, 0 , "@!" } ) 
aAdd( AcolZ93 , { "ADMISSAO"           , "ADMISSA"  , "D" , 08 , 0 , "@!" } ) 
aAdd( AcolZ93 , { "FIM DO CONTRATO"    , "DTFIMCT"  , "D" , 08 , 0 , "@!" } ) 
aAdd( AcolZ93 , { "DEMISSAO"           , "DEMISSA"  , "D" , 08 , 0 , "@!" } ) 
aAdd( AcolZ93 , { "DATA CANCELAMENTO"  , "XDTCANC"  , "D" , 08, 0 , "@!" } ) 
*/aAdd( AcolZ93 , { "CONTRATO"           , "CONTRATO" , "C" , 15 , 0 , "@!" } ) 
//aAdd( AcolZ93 , { "LOCALIZACAO"        , "LOCALIZ"  , "C" , 15, 0 , "@!" } ) 






//aAdd( Acolun1 , { "TIPO"      , "TIPO"       , "C" , 01 , 0 , "@!" } ) 
//aAdd( Acolun1 , { "CONTRATO"  , "CONTRATO"   , "C" , 15 , 0 , "@!" } ) 
//aAdd( Acolun1 , { "UNIFICADOR", "UNIFICADOR" , "C" , 15 , 0 , "@!" } ) 
//aAdd( Acolun1 , { "EMPRESA"   , "EMPRESA"    , "C" , 150, 0 , "@!" } ) 

//aAdd( Acolun2 , { "TIPO"      , "TIPO"       , "C" , 01 , 0 , "@!" } ) 
aAdd( Acolun2 , { "CONTRATO"  , "CONTRATO"   , "C" , 15 , 0 , "@!" } ) 
aAdd( Acolun2 , { "LOCAL"     , "LOCALIZA"   , "C" , 15 , 0 , "@!" } ) 
aAdd( Acolun2 , { "UNIFICADOR", "UNIFICADOR" , "C" , 15 , 0 , "@!" } ) 
aAdd( Acolun2 , { "EMPRESA"   , "EMPRESA"    , "C" , 150, 0 , "@!" } ) 


aAdd( Acolun3 , { "CONTRATO"                 , "CONTRATO"   , "C" , 15 , 0 , "@!" } ) 
aAdd( Acolun3 , { "LOCAL"                    , "LOCALIZ"    , "C" , 11, 0  , "@!" } ) //INCLUIDO
aAdd( Acolun3 , { "ID EST/APREN"             , "XID"        , "C" , 15 , 0 , "@!" } ) 
aAdd( Acolun3 , { "NOME"                     , "NOME"       , "C" , 30 , 0 , "@!" } ) 
aAdd( Acolun3 , { "CPF"                      , "CIC"        , "C" , 11, 0  , "@!" } ) 
aAdd( Acolun3 , { "COMPET"                   , "COMPET"     , "C" , 06, 0  , "@!" } ) 
aAdd( Acolun3 , { "ADMISSAO"                 , "ADMISSA"    , "D" , 08 , 0 , "@!" } ) 
aAdd( Acolun3 , { "DATA FIM CONTRATO"        , "DTFIMCT"    , "C" , 15 , 0 , "@!" } ) 
aAdd( Acolun3 , { "DEMISSAO"                 , "DEMISSA"    , "C" , 30 , 0 , "@!" } ) 
aAdd( Acolun3 , { "DATA CANCELAMENTO"        , "XDTCANC"    , "C" , 11, 0  , "@!" } ) 
//aAdd( Acolun3 , { "LOCAL"                    , "LOCALIZ"    , "C" , 11, 0  , "@!" } ) 



CursorWait()

Begin Sequence

   cAlias := Left(oTree:GetCargo(),4)

   If Left (cAlias,4) <> "ZC3P"  .And. Left (cAlias,4) <> "ZC4P" 
      cAlias:= Left (cAlias,3) 
   Endif

   nRecno := Val(SubStr(oTree:GetCargo(), 4))

   lFound := nRecno <> 0

   If !lFound
      If ValType(oMsMGet) == "O"
         //oMsMGet:Hide()
      EndIf
      If ValType(oMsGetDados) == "O"
         //oMsGetDados:Hide()
      EndIf
      Alert("Sem Dados para apresentar.")
      Break
   EndIf

   // (cAlias)->(dbGoTo(nRecno))

   oPanelView:FreeChildren()  //Elimina (libera) todos os objetos da classe oPanel.

   If ! cAlias $ "SE1|SC5|SF2"
      AtualizaTRB(cAlias )  // Monta arquivo temporario dos contratos conforme Titulo em questão.
   ENDIF 

   aHeigt1  := VerResM1()
   nHeigUP1 := aHeigt1[1]
   nHeiDow1 := aHeigt1[2]

   Do Case

      Case cAlias == "ZC1"

         //LISTA DOS CONTRATOS (TEMPORARIO)
         oFWLayer := FWLayer():New()
         oFWLayer:Init( oPanelView, .F., .T. )
         //oFWLayer:addLine( 'UP', 30, .F. )
         oFWLayer:addLine( 'UP', nHeigUP1, .F. )
         oPanelUp := oFWLayer:getLinePanel('UP')

         omBrowseUP:= FWMBrowse():New()
         omBrowseUP:SetAlias(cAliasTRB)
         omBrowseUP:SetFields(Acolun2)      
         omBrowseUP:SetTemporary(.T.)

         omBrowseUP:SetAmbiente(.T.)
         omBrowseUP:SetWalkThru(.F.)        
         omBrowseUP:SetFixedBrowse(.T.)    
         omBrowseUP:SetDBFFilter(.T.)
         omBrowseUP:SetUseFilter(.T.)

         omBrowseUP:SetDescription('Contrato: ' + Alltrim(SE1->E1_XIDCNT) )
         omBrowseUP:DisableDetails()
         omBrowseUP:SetProfileID("1")
         omBrowseUP:SetOwner( oPanelUp )
         omBrowseUP:SetIgnoreARotina( .T.)
         omBrowseUP:SetMenuDef("")
         omBrowseUP:AddButton('Ver Contrato', 'U_FI89VERCT()', , 4, 0)  
         omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='1'"	, "BLUE"		, "Contrato Normal")
         omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='2'"	, "GREEN"	, "Contrato Unificador")
         omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='3'"	, "YELLOW"	, "Contrato Unificado")
         omBrowseUP:Activate()

         //LISTA DOS LOCAIS DE CONTRATOS (ZC1)
         //oFWLayer:addLine( 'MEIO',30, .F. )
         oFWLayer:addLine( 'MEIO',nHeiDow1, .F. )
         oPanelMeio:= oFWLayer:getLinePanel('MEIO')
         omBrowseMeio:= FWMBrowse():New()
         omBrowseMeio:SetAlias('ZC1')
         omBrowseMeio:SetDescription('Local de Contratos: ' + Alltrim(SE1->E1_XIDLOC))
         omBrowseMeio:DisableDetails()
         omBrowseMeio:SetProfileID("2")
         omBrowseMeio:SetOwner( oPanelMeio )
         omBrowseMeio:SetIgnoreARotina( .T.)
         omBrowseMeio:SetMenuDef("")
         omBrowseMeio:AddButton('Ver Local', 'AxVisual', , 4, 0)  
         omBrowseMeio:Activate()

         oRelation := FWBrwRelation():New()
         oRelation:AddRelation( omBrowseUP, omBrowseMeio, {    {'ZC1->ZC1_FILIAL','xFilial( "ZC1" )' } ,;
                                                               {'ZC1->ZC1_CODIGO','(cAliasTRB)->CONTRATO','=='},;
                                                               {'ZC1->ZC1_LOCCTR','(cAliasTRB)->LOCALIZA','==' }} )
         oRelation:Activate()

      Case cAlias == "ZC3"  .Or. cAlias == "ZC3P"     //Configuração de Cobrança  

         oFWLayer := FWLayer():New()
         oFWLayer:Init( oPanelView, .F., .T. )
         oFWLayer:addLine( 'UP', 40, .F. )
         oPanelUp := oFWLayer:getLinePanel('UP')

         omBrowseUP:= FWMBrowse():New()
         omBrowseUP:SetAlias(cAliasTRB)
         omBrowseUP:SetFields(Acolun2)      
         omBrowseUP:SetTemporary(.T.)
         omBrowseUP:SetDescription('Contrato: ' + Alltrim(SE1->E1_XIDCNT) + " - Local: " + Alltrim(SE1->E1_XIDLOC) )
         omBrowseUP:DisableDetails()
         omBrowseUP:SetProfileID("1")
         omBrowseUP:SetOwner( oPanelUp )
         omBrowseUP:SetIgnoreARotina( .T.)
         omBrowseUP:SetMenuDef("")
         omBrowseUP:AddButton('Ver Contrato', 'U_FI89VERCT()', , 4, 0)  
         omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='1'"	, "BLUE"		, "Contrato Normal")
         omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='2'"	, "GREEN"	, "Contrato Unificador")
         omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='3'"	, "YELLOW"	, "Contrato Unificado")
         omBrowseUP:Activate()

         oFWLayer:addLine( 'DOWN',50, .F. )
         oPanelDown:= oFWLayer:getLinePanel('DOWN')
         omBrowseDown:= FWMBrowse():New()
         omBrowseDown:SetAlias('ZC3')
         omBrowseDown:SetDescription('Configuração de Cobrança: ' + cCodIDCobra)
         omBrowseDown:DisableDetails()
         //omBrowseDown:SetFilterDefault("ZC7_IDCNTT+ZC7_IDLOCC == SE2->E2_XIDCNT + SE2->E2_XIDLOC ")
         omBrowseDown:SetFilterDefault("ZC3->ZC3_IDCOBR == ZC5->ZC5_CONCOB ")
         omBrowseDown:SetProfileID("2")
         omBrowseDown:SetOwner( oPanelDown )
         omBrowseDown:SetIgnoreARotina( .T.)
         omBrowseDown:SetMenuDef("")
         omBrowseDown:AddButton('Visualizar', 'AxVisual', , 4, 0) 
         omBrowseDown:Activate()

         oRelatSZ3:= FWBrwRelation():New()
         oRelatSZ3:AddRelation( omBrowseUP, omBrowseDown,   {  {'ZC3->ZC3_FILIAL','xFilial( "ZC3" )' } ,;
                                                               {'ZC3->ZC3_IDCONT','(cAliasTRB)->CONTRATO','=='}} )
                                                               //,;{'ZC3->ZC3_LOCCTR','(cAliasTRB)->LOCALIZA','==' } 
         oRelatSZ3:Activate()

      Case cAlias == "ZC4"  .Or. cAlias == "ZC4P"     // Configuração da Fatura

         oFWLayer := FWLayer():New()
         oFWLayer:Init( oPanelView, .F., .T. )
         oFWLayer:addLine( 'UP', 40, .F. )
         oPanelUp := oFWLayer:getLinePanel('UP')

         omBrowseUP:= FWMBrowse():New()
         omBrowseUP:SetAlias(cAliasTRB)
         omBrowseUP:SetFields(Acolun2)      
         omBrowseUP:SetTemporary(.T.)
         omBrowseUP:SetDescription('Contrato: ' + Alltrim(SE1->E1_XIDCNT) + " - Local: " + Alltrim(SE1->E1_XIDLOC) )
         omBrowseUP:DisableDetails()
         omBrowseUP:SetProfileID("1")
         omBrowseUP:SetOwner( oPanelUp )
         omBrowseUP:SetIgnoreARotina( .T.)
         omBrowseUP:SetMenuDef("")
         omBrowseUP:AddButton('Ver Contrato', 'U_FI89VERCT()', , 4, 0)  
         omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='1'"	, "BLUE"		, "Contrato Normal")
         omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='2'"	, "GREEN"	, "Contrato Unificador")
         omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='3'"	, "YELLOW"	, "Contrato Unificado")
         omBrowseUP:Activate()

         oFWLayer:addLine( 'DOWN',50, .F. )
         oPanelDown:= oFWLayer:getLinePanel('DOWN')
         omBrowseDown:= FWMBrowse():New()
         omBrowseDown:SetAlias('ZC4')
         omBrowseDown:SetDescription('Configuração da Fatura: ' + cCodIDFatur)
         omBrowseDown:DisableDetails()
         omBrowseDown:SetFilterDefault("ZC4->ZC4_IDFATU == ZC5->ZC5_CONFAT ")
         //omBrowseDown:SetFilterDefault("")
         omBrowseDown:SetProfileID("2")
         omBrowseDown:SetOwner( oPanelDown )
         omBrowseDown:SetIgnoreARotina( .T.)
         omBrowseDown:SetMenuDef("")
         omBrowseDown:AddButton('Visualizar', 'AxVisual', , 4, 0) 
         omBrowseDown:Activate()

         oRelatSZ4:= FWBrwRelation():New()
         oRelatSZ4:AddRelation( omBrowseUP, omBrowseDown,   {  {'ZC4->ZC4_FILIAL','xFilial( "ZC4" )' } ,;
                                                               {'ZC4->ZC4_IDCONT','(cAliasTRB)->CONTRATO','==' }} )
                                                               //,;{'ZC4->ZC4_LOCCTR','(cAliasTRB)->LOCALIZA','==' }
         oRelatSZ4:Activate()

      Case cAlias == "SRA"    //Analitico: Provisórios
      
          //LISTA DOS CONTRATOS (TEMPORARIO)
            oFWLayer := FWLayer():New()
            oFWLayer:Init( oPanelView, .F., .T. )
            oFWLayer:addLine( 'UP', 40, .F. )
            oPanelUp := oFWLayer:getLinePanel('UP')

            omBrowseUP:= FWMBrowse():New()
            omBrowseUP:SetAlias(cAliasTRB)
            omBrowseUP:SetFields(Acolun2)      
            omBrowseUP:SetTemporary(.T.)
            omBrowseUP:SetDescription('Contrato: ' + Alltrim(SE1->E1_XIDCNT) + " - Local: " + Alltrim(SE1->E1_XIDLOC) )
            omBrowseUP:DisableDetails()
            omBrowseUP:SetProfileID("1")
            omBrowseUP:SetOwner( oPanelUp )
            omBrowseUP:SetIgnoreARotina( .T.)
            omBrowseUP:SetMenuDef("")
            omBrowseUP:AddButton('Ver Contrato', 'U_FI89VERCT()', , 4, 0)  
            omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='1'"	, "BLUE"		, "Contrato Normal")
            omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='2'"	, "GREEN"	, "Contrato Unificador")
            omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='3'"	, "YELLOW"	, "Contrato Unificado")
            omBrowseUP:Activate()

            oFWLayer:addLine( 'DOWN',60, .F. )
            oPanelDown:= oFWLayer:getLinePanel('DOWN')
            omBrowseDown:= FWMBrowse():New()
            omBrowseDown:SetAlias('SRA')
            omBrowseDown:SetDescription('Analitico dos Provisórios:')
            omBrowseDown:DisableDetails()
            omBrowseDown:SetAmbiente(.T.)
            omBrowseDown:SetUseFilter(.T.)
            //omBrowseDown:SetFilterDefault("SRA->RA_FILIAL+SRA->RA_XIDCONT+SRA->RA_XIDLOCT == xFilial('SRA') + (cAliasTRB)->CONTRATO + (cAliasTRB)->LOCALIZA ")
            omBrowseDown:SetProfileID("2")
            omBrowseDown:SetOwner( oPanelDown )
            omBrowseDown:SetIgnoreARotina( .T.)
            omBrowseDown:SetMenuDef("")
            omBrowseDown:AddButton('Visualizar', 'AxVisual', , 4, 0)  
            omBrowseDown:Activate()

            oRelatSra:= FWBrwRelation():New()
            oRelatSra:AddRelation( omBrowseUP, omBrowseDown, {  {'SRA->RA_FILIAL','xFilial( "SRA" )' } ,;
                                                                {'SRA->RA_XIDCONT','(cAliasTRB)->CONTRATO','==' },;
                                                                {'SRA->RA_XIDLOCT','(cAliasTRB)->LOCALIZA','==' }} )
            oRelatSra:Activate()

      Case cAlias == "ZC5"    // Registro da Fatura

/*         If ! cAlias $ "SE1|SC5|SF2"
            AtualizaTRB(cAlias )  // Monta arquivo temporario dos contratos conforme Titulo em questão.
         ENDIF 
*/
            oFWLayer := FWLayer():New()
            oFWLayer:Init( oPanelView, .F., .T. )
//            oFWLayer:addLine( 'UP', 50, .F. )
            oFWLayer:addLine( 'UP', 40, .F. )

            oPanelUp := oFWLayer:getLinePanel('UP')


            omBrowseUP:= FWMBrowse():New()
            omBrowseUP:SetAlias(cAliasTRB)
            omBrowseUP:SetFields(Acolun2)      
            omBrowseUP:SetTemporary(.T.)
            omBrowseUP:SetDescription('Contrato: ' + Alltrim(SE1->E1_XIDCNT) + " - Local: " + Alltrim(SE1->E1_XIDLOC) )
            omBrowseUP:DisableDetails()
            omBrowseUP:SetProfileID("1")
            omBrowseUP:SetOwner( oPanelUp )
            omBrowseUP:SetIgnoreARotina( .T.)
            omBrowseUP:SetMenuDef("")
            omBrowseUP:AddButton('Ver Contrato', 'U_FI89VERCT()', , 4, 0)  
            omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='1'"	, "BLUE"		, "Contrato Normal")
            omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='2'"	, "GREEN"	, "Contrato Unificador")
            omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='3'"	, "YELLOW"	, "Contrato Unificado")
            omBrowseUP:Activate()

//            oFWLayer:addLine( 'DOWN',50, .F. )
            oFWLayer:addLine( 'DOWN',40, .F. )
//            oFWLayer:addCollumn( 'DOWN',30, .F. )
            oPanelDown:= oFWLayer:getLinePanel('DOWN')
            omBrowseDown:= FWMBrowse():New()
            omBrowseDown:SetAlias('ZC5')
            omBrowseDown:SetDescription('Registro da Fatura**:')
            omBrowseDown:DisableDetails()
            //omBrowseDown:SetFilterDefault("")
            omBrowseDown:SetUseFilter(.T.)
            omBrowseDown:SetFilterDefault("ZC5->ZC5_IDFATU == SE1->E1_XIDFATU")
            omBrowseDown:SetProfileID("2")
            omBrowseDown:SetOwner( oPanelDown )
            omBrowseDown:SetIgnoreARotina( .T.)
            omBrowseDown:SetMenuDef("")
            omBrowseDown:AddButton('Visualizar', 'AxVisual', , 4, 0) 
            omBrowseDown:Activate()

            oRelatSZ5:= FWBrwRelation():New()
            oRelatSZ5:AddRelation( omBrowseUP, omBrowseDown,   {  {'ZC5->ZC5_FILIAL','xFilial( "ZC5" )' } ,;
                                                                  {'ZC5->ZC5_IDCONT','(cAliasTRB)->CONTRATO','==' },;
                                                                  {'ZC5->ZC5_LOCCON','(cAliasTRB)->LOCALIZA','==' }} )
            oRelatSZ5:Activate()


  /*          oRelatSRA:= FWBrwRelation():New()
            oRelatSRA:AddRelation( omBrowseUP, omBrowseDown,   {  {'SRA->RA_FILIAL','xFilial( "ZC5" )' } ,;
                                                                  {'SRA->RA_XIDCONT','(cAliasTRB)->CONTRATO','==' },;
                                                                  {'SRA->RA_XIDLOCT','(cAliasTRB)->LOCALIZA','==' }} )
            oRelatSRA:Activate()
*/


      Case cAlias == "ZC6"    // Analitico Faturamentos

         oFWLayer := FWLayer():New()
         oFWLayer:Init( oPanelView, .F., .T. )
         oFWLayer:addLine( 'UP', nHeigUP1, .F. ) //20->1920
         oPanelUp := oFWLayer:getLinePanel('UP')

         omBrowseUP:= FWMBrowse():New()
         omBrowseUP:SetAlias(cAliasTRB)
    //     omBrowseUP:SetAlias("ZC6")
//         omBrowseUp:SetFilterDefault("ZC6->ZC6_IDFATU == SE1->E1_XIDFATU ")         
         omBrowseUP:SetFields(Acolun2)      
         omBrowseUP:SetTemporary(.T.)
         omBrowseUP:SetDescription('Contrato: ' + Alltrim(SE1->E1_XIDCNT) + " - Local: " + Alltrim(SE1->E1_XIDLOC) )
         omBrowseUP:DisableDetails()
         omBrowseUP:SetProfileID("1")
         omBrowseUP:SetOwner( oPanelUp )
         omBrowseUP:SetIgnoreARotina( .T.)
         omBrowseUP:SetMenuDef("")
         omBrowseUP:AddButton('Ver Contrato', 'U_FI89VERCT()', , 4, 0)  
         omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='1'"	, "BLUE"		, "Contrato Normal")
         omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='2'"	, "GREEN"	, "Contrato Unificador")
         omBrowseUP:AddLegend( "(cAliasTRB)->TIPO =='3'"	, "YELLOW"	, "Contrato Unificado")
         omBrowseUP:Activate()



//         oFWLayer := FWLayer():New()
         oFWLayer:Init( oPanelView, .F., .T. )
         //oFWLayer:addLine( 'DOWN', 70, .F. )  
         oFWLayer:addLine( 'DOWN', nHeiDow1, .F. )  
         oPanelDown := oFWLayer:getLinePanel('DOWN')

         omBrowseDown:= FWMBrowse():New()
         omBrowseDown:SetAlias("Z93")
    //     omBrowseUP:SetAlias("ZC6")
//         omBrowseUp:SetFilterDefault("ZC6->ZC6_IDFATU == SE1->E1_XIDFATU ")         
         omBrowseDown:SetFields(Acolun3)      
         omBrowseDown:SetTemporary(.T.)
//         omBrowseDown:SetDescription('Contrato***: ' + Alltrim(SE1->E1_XIDCNT) + " - Local: " + Alltrim(SE1->E1_XIDLOC) )
         omBrowseDown:SetDescription('Analitico Faturamentos:')            
         omBrowseDown:DisableDetails()
         omBrowseDown:SetProfileID("1")
         omBrowseDown:SetOwner( oPanelDOWN )
         omBrowseDown:SetIgnoreARotina( .T.)
         omBrowseDown:SetMenuDef("")
//         omBrowseDown:AddButton('Ver Contrato', 'U_FI89VERCT()', , 4, 0)  
//         omBrowseDown:AddButton('Visualizar', 'AxVisual', , 4, 0) 

//         omBrowseDown:AddLegend( "(cAliasTRB)->TIPO =='1'"	, "BLUE"		, "Contrato Normal")
//         omBrowseDown:AddLegend( "(cAliasTRB)->TIPO =='2'"	, "GREEN"	, "Contrato Unificador")
//         omBrowseDown:AddLegend( "(cAliasTRB)->TIPO =='3'"	, "YELLOW"	, "Contrato Unificado")
         omBrowseDown:Activate()



/*----------------------------------------
         oFWLayer:addLine( 'DOWN',40, .F. )
         oPanelDown:= oFWLayer:getLinePanel('DOWN')
         omBrowseDown:= FWMBrowse():New()
         omBrowseDown:SetAlias('SRA')
//         omBrowseDown:SetAlias('Z93')
//         omBrowseDown:SetFields(AcolZ93)  
         omBrowseUP:SetTemporary(.T.)     
         omBrowseDown:SetDescription('Analitico Faturamentos:')   
         omBrowseDown:DisableDetails() 
         omBrowseDown:SetProfileID("2")  
         omBrowseDown:SetOwner( oPanelDown )                                             
//         omBrowseDown:SetOnlyFields( { 'Z93->CONTRATO' } )         
         omBrowseDown:SetOnlyFields( { 'RA_XID','RA_NOME','RA_CIC','RA_ADMISSA','RA_DTFIMCT','RA_DEMISSA','RA_XDTCANC' } )         
        omBrowseDown:SetFilterDefault("SRA->RA_FILIAL+SRA->RA_XID == Z93->FILIAL + Z93->XID ")
//         omBrowseDown:SetFilterDefault(" Z93->CONTRATO == SE1->E1_XIDCNT ")
//         omBrowseDown:SetUseFilter(.T.)
//         omBrowseDown:SetFilterDefault("(ZC6->ZC6_FILIAL+ZC6->ZC6_IDCONT+ZC6->ZC6_LOCCON == xFilial('ZC6') + (cAliasTRB)->CONTRATO + (cAliasTRB)->LOCALIZA)") //  .AND. (SRA->RA_FILIAL+SRA->RA_XID == xFilial('ZC6') + ZC6->ZC6_TCETCA) ")
         //omBrowseDown:SetFilterDefault("")
         omBrowseDown:SetIgnoreARotina( .T.)
         omBrowseDown:SetMenuDef("")
         omBrowseDown:AddButton('Visualizar', 'AxVisual', , 4, 0) 
         omBrowseDown:Activate()
*///----------------------------------------------------------
/*         oRelatSZ6:= FWBrwRelation():New()
         oRelatSZ6:AddRelation( omBrowseUP, omBrowseDown,   {  {'ZC6->ZC6_FILIAL','xFilial( "ZC6" )' } ,;
                                                               {'ZC6->ZC6_IDCONT','(cAliasTRB)->CONTRATO','==' },;
                                                               {'ZC6->ZC6_LOCCON','(cAliasTRB)->LOCALIZA','==' }} )
         oRelatSZ6:Activate()
*/
/*      oRelatSRA:= FWBrwRelation():New()
            oRelatSRA:AddRelation( omBrowseUP, omBrowseDown,   {  {'SRA->RA_FILIAL','xFilial( "ZC6" )' } ,;
                                                                  {'SRA->RA_XIDCONT','(cAliasTRB)->CONTRATO','==' },;
                                                                  {'SRA->RA_XIDLOCT','(cAliasTRB)->LOCALIZA','==' }} )
            oRelatSRA:Activate()*/
/*
      oRelatSRA:= FWBrwRelation():New()
            oRelatSRA:AddRelation( omBrowseUP, omBrowseDown,   {  {'SRA->RA_FILIAL','Z93->FILIAL' } ,;
                                                                  {'SRA->RA_XIDCONT','Z93->CONTRATO','==' },;
                                                                   {'SRA->RA_XID','Z93->XID','==' },;
                                                                  {'SRA->RA_XIDLOCT','Z93->LOCALIZ','==' }} )
            oRelatSRA:Activate()
*/
  /*    oRelatSRA:= FWBrwRelation():New()
            oRelatSRA:AddRelation( omBrowseUP, omBrowseDown,   {  {'Z93->FILIAL','xFilial( "ZC6" )' } ,;
                                                                  {'Z93->CONTRATO','(cAliasTRB)->CONTRATO', },;
                                                                   {'Z93->LOCALIZ','(cAliasTRB)->LOCALIZA', }} )
            oRelatSRA:Activate()*/




   
   
   
      Case cAlias == "SC5"
         aSizeT := FwDefSize():New(.T.)
      if aSizeT:AWINDSIZE[3] > 600
         aSize := {10, 5, 290, 830}
      else
         aSize := {10, 5, 130, 515}   
      endif         
//         aSize := {10, asizet:AWINDSIZE[2], asizet:AWINDSIZE[3], asizet:AWINDSIZE[4]}
         cSeek   := xFilial("SC6")+SC5->C5_NUM
         bWhile  := {|| C6_FILIAL+C6_NUM}
         cAliasD := "SC6"
         nOrderD := 1

      Case cAlias == "SF2"
         aSizeT := FwDefSize():New(.T.)
      if aSizeT:AWINDSIZE[3] > 600
         aSize := {10, 5, 290, 800}
      else
         aSize := {10, 5, 130, 515}
      endif
         cSeek   := xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA
         bWhile  := {|| D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA}
         cAliasD := "SD2"
         nOrderD := 3

      Otherwise


      aSizeT := FwDefSize():New(.T.)
      if aSizeT:AWINDSIZE[3] > 600
          aSize := {10, 5, 460, 790}
      else
          aSize := {10, 5, 260, 515}
      endif
  // aSize := FwDefSize():New(.T.,,,oDlg)   
   //aSize := FwDefSize():New(.T.)   

   End Case

   If cAlias == "SE1" .Or. cAlias == "SC5" .Or. cAlias == "SF2" 
    
      dbSelectArea(cAlias)

      //Carrega as propriedades para o objeto oMsMGet.
      oStruAlias := FWFormStruct(1, cAlias)

      For nPos := 1 To Len(oStruAlias:aFields)
         Aadd(aAcho, AllTrim(oStruAlias:aFields[nPos, MODEL_FIELD_IDFIELD]))
      Next

      RegToMemory(cAlias, .F., .F., .F.)

      oMsMGet:= MsMGet():New(cAlias, (cAlias)->(Recno()), 2, , , , aAcho, aSize, , 3, , , , oPanelView, .F., .T., .F.,,, .T.)
      oMsMGet:Refresh()

      If cAlias == "SC5"
         aHeader := {}
         aCols	  := {}
         FillGetDados( 2, cAliasD, nOrderD, cSeek, bWhile,,, /*aYesFields*/, /*lOnlyYes*/,, /*bMontCols*/, .F., /*aHeaderAux*/, /*aColsAux*/, , /*bBeforeCols*/,/*bAfterHeader*/, cAliasD )
         aSizeT := FwDefSize():New(.T.)
      if aSizeT:AWINDSIZE[3] > 600
         oMsGetDados := MsNewGetDados():New( 290, 5, 420, 820, GD_INSERT+GD_DELETE+GD_UPDATE,,,,, 0, 99,,,, oPanelView, aHeader, aCols)
      else
         oMsGetDados := MsNewGetDados():New( 132, 5, 260, 518, GD_INSERT+GD_DELETE+GD_UPDATE,,,,, 0, 99,,,, oPanelView, aHeader, aCols)
      endif
         oMsGetDados:lInsert := .F.
         oMsGetDados:lDelete := .F.
         oMsGetDados:lUpdate := .F.
         oMsGetDados:ForceRefresh() 
      ENDIF
      If cAlias  == "SF2"
         aHeader := {}
         aCols	  := {}
         FillGetDados( 2, cAliasD, nOrderD, cSeek, bWhile,,, /*aYesFields*/, /*lOnlyYes*/,, /*bMontCols*/, .F., /*aHeaderAux*/, /*aColsAux*/, , /*bBeforeCols*/,/*bAfterHeader*/, cAliasD )
         aSizeT := FwDefSize():New(.T.)
      if aSizeT:AWINDSIZE[3] > 600
            oMsGetDados := MsNewGetDados():New( 290, 5, 420, 820, GD_INSERT+GD_DELETE+GD_UPDATE,,,,, 0, 99,,,, oPanelView, aHeader, aCols)
         else
            oMsGetDados := MsNewGetDados():New( 132, 5, 260, 518, GD_INSERT+GD_DELETE+GD_UPDATE,,,,, 0, 99,,,, oPanelView, aHeader, aCols)
      endif
         oMsGetDados:lInsert := .F.
         oMsGetDados:lDelete := .F.
         oMsGetDados:lUpdate := .F.
         oMsGetDados:ForceRefresh() 
      ENDIF

   
   Endif

End Sequence

oPanelView:Refresh()

CursorArrow()

Return(.T.)


/*
Função    : CFINA88TView
Objetivo  : Visualização do Cadastro Original da tabela.
Parametro : oTree : Objeto Tree.
Retorno   : Nil
Autor     : Alexsander Martins dos Santos
Data      : 12/12/2019
Empresa   : CIEE
*/

Static Function CFINA88TView(oTree)

Local cAlias
Local nRecno
Local lFound
Local cTitulo
Local cPrograma

Begin Sequence

   cAlias := Left(oTree:GetCargo(), 3)

   nRecno := Val(SubStr(oTree:GetCargo(), 4))

   lFound := nRecno <> 0

   If !lFound
      Break
   EndIf

   Do Case

      Case cAlias == "SE1"
         cTitulo   := "Contas a Receber"
         cPrograma := "XFA280View"  //"FinA040"  //FA280Visua

         FA280Visua("SE1", SE1->(Recno()), 2)
         Break

      Case cAlias == "ZC1"
         cTitulo   := "Contrato e Local de Contrato"
         cPrograma := "CCADK01"

      Case cAlias == "ZC4"
         cTitulo   := "Configurações de Faturamento"
         cPrograma := "CCADK04"

      Case cAlias == "ZC3"
         cTitulo   := "Configurações de Cobrança"
         cPrograma := "CCADK03"

      Case cAlias == "ZC2"
         cTitulo   := "Configurações da Folha"
         cPrograma := "CCADK02"

      Case cAlias == "ZC5"
         cTitulo   := "Registro de Faturamento"
         cPrograma := "CFATA01" 

      Case cAlias == "SC5"
         cTitulo   := "Pedido de Venda"
         cPrograma := "MATA410"

         A410Visual("SC5", SC5->(Recno()), 2)
         Break

      Case cAlias == "SF2"
         cTitulo   := "Documento de Saída"
         cPrograma := "CFATA01"

      Otherwise
         MsgAlert(cAlias, "Sem Visualização")
         Break

   End Case

   FWExecView("Tracker Kairos - "+cTitulo , cPrograma, MODEL_OPERATION_VIEW,, {|| .T.}, {|| .T.}, 40,, {|| .T.},,,)


End Sequence

Return(Nil)


//----------------------------------------------------------------------------------
/*{Protheus.doc} CriaTRB1
Cria Tabela Temporaria (Estrutura) para as APRESENTAÇÃO dos Contratos dos Titulos Provisórios e Normais
Considerando o conceito de contrato unificado que pode ou não existir
@author Luiz Enrique de Araujo
@since 24/06/2020
@project  
/*/   
//-----------------------------------------------------------------------------------
/*Static Function CriaTRB1()

aCampos := {}  

If Select(cAliasTRB) > 0
	DBSelectArea(cAliasTRB)
	DBCloseArea()
	FErase(AllTrim(cFileTRB)+GetDBExtension())
	FErase(AllTrim(cFileTRB+"A")+OrdBagExt()) 		
EndIf

cAliasTRB := GetNextAlias()

AADD(aCampos,{"TIPO"     	,"C",01,0})    //1=Contrato Normal, 2=Contrato Unificador, 3=Contrato Unificado
AADD(aCampos,{"CONTRATO"  	,"C",15,0})    //Numero do Contrato
AADD(aCampos,{"UNIFICADOR" ,"C",15,0})    //Numero do Contrato Unificador
AADD(aCampos,{"EMPRESA"    ,"C",150,0})   //ZC0_NOME     - Nome da Empresa

If Select(cAliasTRB) > 0
	DBSelectArea(cAliasTRB)
	DBCloseArea()
	FErase(AllTrim(cFileTRB)+GetDBExtension())
	FErase(AllTrim(cFileTRB+"A")+OrdBagExt()) 		
EndIf

cFileTRB := CriaTrab(aCampos) 
DBCreate(cFileTRB,aCampos)
DBUseArea(.T.,,cFileTRB,cAliasTRB,.F.,.F.) // Exclusivo
IndRegua(cAliasTRB,cFileTRB+"A","CONTRATO",,,OemToAnsi("Organizando Arquivo.."))
DBClearIndex()
DBSetIndex(cFileTRB+"A"+OrdBagExt())

Return*/

//----------------------------------------------------------------------------------
/*{Protheus.doc} CriaTRB2
Cria Tabela Temporaria (Estrutura) para FILTRAR os Contratos 
Considerando o conceito de contrato unificado que pode ou não existir
@author Luiz Enrique de Araujo
@since 24/06/2020
@project  
/*/   
//-----------------------------------------------------------------------------------
Static Function CriaTRB2()

aCampos := {} 

cAliasTRB := GetNextAlias()

AADD(aCampos,{"TIPO"     	,"C",01,0})    //1=Contrato Normal, 2=Contrato Unificador, 3=Contrato Unificado
AADD(aCampos,{"CONTRATO"  	,"C",15,0})    //Numero do Contrato
AADD(aCampos,{"LOCALIZA"   ,"C",15,0})    //Local do Contrato
AADD(aCampos,{"UNIFICADOR" ,"C",15,0})    //Numero do Contrato Unificador
AADD(aCampos,{"EMPRESA"    ,"C",150,0})   //Nome da Empresa
AADD(aCampos,{"TCETCA"     ,"C",15,0})    //Registro Estagiario


U_uCriaTrab(cAliasTRB,aCampos,{ {"CONTRATO"}})

(cAliasTRB)->(DbSetOrder(1))





	PRIVATE AARQTRB := {}

   AADD(AARQTRB,{"FILIAL"    ,"C",04,0})
	AADD(AARQTRB,{"XID"       ,"C",15,0})
   AADD(AARQTRB,{"COMPET"    ,"C",06,0})
	AADD(AARQTRB,{"NOME"      ,"C",30,0})
	AADD(AARQTRB,{"CIC"       ,"C",11,0})
	AADD(AARQTRB,{"ADMISSA"   ,"D",08,0})
	AADD(AARQTRB,{"DTFIMCT"   ,"D",08,0})
	AADD(AARQTRB,{"DEMISSA"   ,"D",08,0})
	AADD(AARQTRB,{"XDTCANC"   ,"D",08,0})
	AADD(AARQTRB,{"CONTRATO"  ,"C",15,0})
	AADD(AARQTRB,{"LOCALIZ"   ,"C",15,0})

	if select("Z93")>0
		Z93->(DBCLOSEAREA())
	endif

	CARQTRB := CRIATRAB(AARQTRB,.T.)
	DBUSEAREA(.T.,,CARQTRB,"Z93")

	INDEX ON XID+COMPET TO &CARQTRB





/*
If Select(cAliasTRB) > 0
	DBSelectArea(cAliasTRB)
	DBCloseArea()
	FErase(AllTrim(cFileTRB)+GetDBExtension())
	FErase(AllTrim(cFileTRB+"A")+OrdBagExt()) 		
EndIf

cFileTRB := CriaTrab(aCampos) 
DBCreate(cFileTRB,aCampos)
DBUseArea(.T.,,cFileTRB,cAliasTRB,.F.,.F.) // Exclusivo
IndRegua(cAliasTRB,cFileTRB+"A","CONTRATO",,,OemToAnsi("Organizando Arquivo.."))
DBClearIndex()
DBSetIndex(cFileTRB+"A"+OrdBagExt())
*/

Return

//----------------------------------------------------------------------------------
/*{Protheus.doc} AtualizaTRB
Monta Lista dos Contratos a serem msotrados no Browse ou utilizados como Filtro para demais visualizações
@author Luiz Enrique de Araujo
@since 24/06/2020
@project  
/*/   
//-----------------------------------------------------------------------------------
Static Function AtualizaTRB(cAlias)

Local aCntLoc:= {}

ZC0->(DBSetOrder(1))
ZC1->(DBSetOrder(1))
ZCB->(DBSetOrder(2)) //ZCB_FILIAL + ZCB_IDCNTU
ZCI->(DBSetOrder(2)) //ZCI_FILIAL + ZCI_IDUNIF

//If  cAlias == "ZC5" .Or. cAlias == "ZC1" //Painel dos Contratos
//  CriaTRB1()
//else
   CriaTRB2()
//Endif

//ZC4P contempla Titulos não Provisórios  - Origem ZC5
//ZC4  contempla Titulos Provisórios      - Origem SE1
//ZC3P Configuração da Cobrança           - Origem ZC5 contempla Titulos não Provisórios
//ZC3  Configuração da Cobrança           - Origem SE1 contempla Titulos Provisórios 
If cAlias == "ZC5" .Or. cAlias == "ZC4P" .Or. cAlias == "ZC3P"    //Contratos Normais, Não provisórios - UNIFICADOR PELA ZCI -  

      ZC5->(dbSetOrder(8))
      ZC5->(dbSeek(SE1->E1_XIDFATU))

   While ZC5->(!EOF()) .and. ZC5->ZC5_FILIAL == Xfilial("ZC5") .and. ZC5->ZC5_IDFATU == SE1->E1_XIDFATU

      If AsCan(aCntLoc,{|x|x[1]+x[2] == ZC5->ZC5_IDCONT + ZC5->ZC5_LOCCON })	 > 0
         ZC5->(DbSkip())
         Loop
      Endif

      If  ZCI->(DBSeek(Xfilial("ZCI") + ZC5->ZC5_IDCONT ))                       //Posiciona na Tabela de Contratos Unificado       
         If ZC1->(dbSeek(xFilial("ZC1") + ZC5->ZC5_IDCONT + ZC5->ZC5_LOCCON  ))  //Posiciona na Tabela de contrato para obter o nome da emepresa                                  
            RecLock(cAliasTRB,.T.) 
            (cAliasTRB)->TIPO:=  	   ZCI->ZCI_TPCONT  
            (cAliasTRB)->CONTRATO:=  	ZC1->ZC1_CODIGO  
            (cAliasTRB)->LOCALIZA:=  	ZC1->ZC1_LOCCTR  
            (cAliasTRB)->UNIFICADOR:= 	ZCI->ZCI_IDUNIF  
            (cAliasTRB)->EMPRESA:=  	ZC1->ZC1_RAZSOC           	
            MsUnlock(cAliasTRB)

            Aadd(aCntLoc,{ ZC5->ZC5_IDCONT,ZC5->ZC5_LOCCON })
         Endif
      Endif

      ZC5->(DbSkip())

   Enddo

Elseif   cAlias == "ZC1" .OR. cAlias == "ZC3"  .OR. cAlias == "ZC4"    //Contratos dos Provisórios  - UNIFICADOR PELA ZCI

      ZCI->(DBSetOrder(3))    //ZCI_FILIAL+ZCI_IDCONT+ZCI_LOCCTR 

      If ZCI->(DBSeek(Xfilial("ZCI") + SE1->E1_XIDCNT + SE1->E1_XIDLOC  )) 

         If ZC1->(dbSeek(xFilial("ZC1") + ZCI->ZCI_IDCONT + ZCI->ZCI_LOCCTR ))    //Posiciona na Tabela de contrato para obter o nome da emepresa                                      
            RecLock(cAliasTRB,.T.) 
            (cAliasTRB)->TIPO:=  	   ZCI->ZCI_TPCONT  
            (cAliasTRB)->CONTRATO:=  	ZC1->ZC1_CODIGO 
            (cAliasTRB)->LOCALIZA:=    ZCI->ZCI_LOCCTR  
            (cAliasTRB)->UNIFICADOR:= 	ZCI->ZCI_IDUNIF    
            (cAliasTRB)->EMPRESA:=  	ZC1->ZC1_RAZSOC          	
            MsUnlock(cAliasTRB)	
         Endif 
      else
          If ZC1->(dbSeek(xFilial("ZC1") + SE1->E1_XIDCNT  + SE1->E1_XIDLOC  ))    //Posiciona na Tabela de contrato para obter o nome da emepresa                                      
            RecLock(cAliasTRB,.T.) 
            (cAliasTRB)->TIPO:=  	   "1"  
            (cAliasTRB)->CONTRATO:=  	SE1->E1_XIDCNT 
            (cAliasTRB)->LOCALIZA:=    SE1->E1_XIDLOC 
            (cAliasTRB)->UNIFICADOR:= 	SE1->E1_XIDCNT    
            (cAliasTRB)->EMPRESA:=  	ZC1->ZC1_RAZSOC          	
            MsUnlock(cAliasTRB)	
         Endif      
      Endif
Elseif   cAlias == "ZC6"   

      ZCI->(DBSetOrder(3))    //ZCI_FILIAL+ZCI_IDCONT+ZCI_LOCCTR 

      If ZCI->(DBSeek(Xfilial("ZCI") + SE1->E1_XIDCNT + SE1->E1_XIDLOC  )) 

         If ZC1->(dbSeek(xFilial("ZC1") + ZCI->ZCI_IDCONT + ZCI->ZCI_LOCCTR ))    //Posiciona na Tabela de contrato para obter o nome da emepresa                                      
            RecLock(cAliasTRB,.T.) 
            (cAliasTRB)->TIPO:=  	   ZCI->ZCI_TPCONT  
            (cAliasTRB)->CONTRATO:=  	ZC1->ZC1_CODIGO 
            (cAliasTRB)->LOCALIZA:=    ZCI->ZCI_LOCCTR  
            (cAliasTRB)->UNIFICADOR:= 	ZCI->ZCI_IDUNIF    
            (cAliasTRB)->EMPRESA:=  	ZC1->ZC1_RAZSOC          	
            MsUnlock(cAliasTRB)	
         Endif 
      else
          If ZC1->(dbSeek(xFilial("ZC1") + SE1->E1_XIDCNT  + SE1->E1_XIDLOC  ))    //Posiciona na Tabela de contrato para obter o nome da emepresa                                      
            RecLock(cAliasTRB,.T.) 
            (cAliasTRB)->TIPO:=  	   "1"  
            (cAliasTRB)->CONTRATO:=  	SE1->E1_XIDCNT 
            (cAliasTRB)->LOCALIZA:=    SE1->E1_XIDLOC 
            (cAliasTRB)->UNIFICADOR:= 	SE1->E1_XIDCNT    
            (cAliasTRB)->EMPRESA:=  	ZC1->ZC1_RAZSOC          	
            MsUnlock(cAliasTRB)	
         Endif      
      Endif

      ZC6->(DBSETORDER(4))

 //     If ZC6->(DBSEEK(xfilial("ZC6")+SE1->E1_XIDFATU))
 //       While ZC6->(!EOF()) .and. ZC6->ZC6_FILIAL == Xfilial("ZC6") .and. ZC6->ZC6_IDFATU == SE1->E1_XIDFATU
      If ZC6->(DBSEEK(SE1->E1_FILORIG+SE1->E1_XIDFATU))
        While ZC6->(!EOF()) .and. ZC6->ZC6_FILIAL == SE1->E1_FILORIG .and. ZC6->ZC6_IDFATU == SE1->E1_XIDFATU
            IF SE1->E1_XAPD=="S" //INDICA QUE UM FATURAMENTO DE APRENDIZ/EMPREGADOR
               DBSELECTAREA("ZCE")
               DBGOTOP()
               DBSETORDER(3)
               //'RA_XID','RA_NOME','RA_CIC','RA_ADMISSA','RA_DTFIMCT','RA_DEMISSA','RA_XDTCANC'
               IF DBSEEK(xFilial("ZCE") + ZC6->ZC6_TCETCA)
                  IF Z93->(!DBSEEK(ZC6->ZC6_TCETCA+ZC6->ZC6_COMPET))
                     RECLOCK("Z93",.T.)
                        Z93->FILIAL   := XFILIAL("SRA")
                        Z93->XID      := ZCE->ZCE_IDESTU //ZCE_IDESTU*INDZCE2   
                        Z93->COMPET   := ZC6->ZC6_COMPET  
                        Z93->NOME     := ZCE->ZCE_NOME //ZCE_NOME
                        Z93->CIC      := ZCE->ZCE_CPF //ZCE_CPF
                        Z93->ADMISSA  := ZCE->ZCE_ADMISS //ZCE_ADMIS
                        Z93->DTFIMCT  := ZCE->ZCE_DTFCTR //ZCE_DTFCTR* Dt.Fim.Contr
                        Z93->DEMISSA  := ZCE->ZCE_DEMISS //ZCE_DEMISS
                        Z93->XDTCANC  := CTOD("")
                        Z93->CONTRATO := ZC6->ZC6_IDCONT
                        Z93->LOCALIZ  := ZC6->ZC6_LOCCON
                     MSUNLOCK("Z93")
                  ENDIF
               ENDIF
            ELSE
               DBSELECTAREA("SRA")
               DBGOTOP()
               DBSETORDER(27)
               //'RA_XID','RA_NOME','RA_CIC','RA_ADMISSA','RA_DTFIMCT','RA_DEMISSA','RA_XDTCANC'
               IF DBSEEK(xFilial("SRA") + ZC6->ZC6_TCETCA)
                  IF Z93->(!DBSEEK(ZC6->ZC6_TCETCA+ZC6->ZC6_COMPET))
                     RECLOCK("Z93",.T.)
                        Z93->FILIAL   := XFILIAL("SRA")
                        Z93->XID      := SRA->RA_XID   
                        Z93->COMPET   := ZC6->ZC6_COMPET   
                        Z93->NOME     := SRA->RA_NOME 
                        Z93->CIC      := SRA->RA_CIC 
                        Z93->ADMISSA  := SRA->RA_ADMISSA 
                        Z93->DTFIMCT  := SRA->RA_DTFIMCT 
                        Z93->DEMISSA  := SRA->RA_DEMISSA 
                        Z93->XDTCANC  := SRA->RA_XDTCANC 
                        Z93->CONTRATO := ZC6->ZC6_IDCONT
                        Z93->LOCALIZ  := ZC6->ZC6_LOCCON
                     MSUNLOCK("Z93")
                  ENDIF
               ENDIF
            ENDIF
            DBSELECTAREA("ZC6")
            DBSKIP()
         Enddo
         DBSELECTAREA("Z93")
         DBGOTOP()
//         INDEX ON Z93->CONTRATO TO "Z93"
      endif





/*Elseif   cAlias == "ZC3" .Or.;   //Configuração de Cobrança 
         cAlias == "ZC4" .Or.;   //Configuração do Faturamento - (Provisorios)
         cAlias == "ZC6" .Or.;   //Analitico: Faturamentos
         cAlias == "SRA"         //Analitico para os Provisórios
*/
Elseif   cAlias == "SRA"   


   ZCI->(DBSeek(Xfilial("ZCI") + SE1->E1_XIDCNT ))  

   While ZCI->(!EOF()) .and. ZCI->ZCI_FILIAL == SE1->E1_FILIAL .and. ZCI->ZCI_IDUNIF  == SE1->E1_XIDCNT
      
       If AsCan(aCntLoc,{|x|x[1]+x[2] == ZCI->ZCI_IDCONT + ZCI->ZCI_LOCCTR })	 > 0
         ZCI->(DbSkip())
         Loop
      Endif

      If ZC1->(dbSeek(xFilial("ZC1") + ZCI->ZCI_IDCONT + ZCI->ZCI_LOCCTR ))    //Posiciona na Tabela de contrato para obter o nome da emepresa   
                                     
         RecLock(cAliasTRB,.T.) 
         (cAliasTRB)->TIPO:=  	   ZCI->ZCI_TPCONT  
         (cAliasTRB)->CONTRATO:=  	ZC1->ZC1_CODIGO 
         (cAliasTRB)->LOCALIZA:=  	ZC1->ZC1_LOCCTR  
         (cAliasTRB)->UNIFICADOR:= 	ZCI->ZCI_IDUNIF    
         (cAliasTRB)->EMPRESA:=  	ZC1->ZC1_RAZSOC          	
         MsUnlock(cAliasTRB)	

         Aadd(aCntLoc,{ ZCI->ZCI_IDCONT,ZCI->ZCI_LOCCTR })

      Endif
      ZCI->(DbSkip())
   Enddo
     
ElseIf cAlias == "ZC2"   //Configuração da Folha   - UNIFICADOR PELA ZCB

   ZCB->(DBSeek(Xfilial("ZCB") + SE1->E1_XIDCNT ))       //Posiciona na Tabela de Contratos Unificado
       
   While ZCB->(!EOF()) .and. ZCB->ZCB_FILIAL == SE1->E1_FILIAL .and. ZCB->ZCB_IDCNTU  == SE1->E1_XIDCNT

      If AsCan(aCntLoc,{|x|x[1]+x[2] == ZCB->ZCB_IDCNT + ZCB->ZCB_IDLOC })	 > 0
         ZCB->(DbSkip())
         Loop
      Endif

      If ZC1->(dbSeek(xFilial("ZC1") + ZCB->ZCB_IDCNT + ZCB->ZCB_IDLOC  ))    //Posiciona na Tabela de contrato para obter o nome da emepresa    

         RecLock(cAliasTRB,.T.) 
         (cAliasTRB)->TIPO:=  	   ZCB->ZCB_TPCONT  
         (cAliasTRB)->CONTRATO:=  	ZC1->ZC1_CODIGO 
         (cAliasTRB)->LOCALIZA:=  	ZC1->ZC1_LOCCTR  
         (cAliasTRB)->UNIFICADOR:= 	ZCB->ZCB_IDCNTU    
         (cAliasTRB)->EMPRESA:=  	ZC1->ZC1_RAZSOC         	
         MsUnlock(cAliasTRB)	

         Aadd(aCntLoc,{ ZCB->ZCB_IDCNT ,ZCB->ZCB_IDLOC })

      Endif
      ZCB->(DbSkip())
   Enddo

Elseif cAlias == "ZC7"  // Folha de bolsa auxílio(Kairós) e Visão Analitica - Analítico da Folha(Kairós)

   //ZC7 ja posicionada
   ZCB->(DBSeek(Xfilial("ZCB") + ZC7->ZC7_IDCNTT ))  

   While ZCB->(!EOF()) .and. ZCB->ZCB_FILIAL == ZC7->ZC7_FILIAL .and. ZCB->ZCB_IDCNTU  == ZC7->ZC7_IDCNTT

      If AsCan(aCntLoc,{|x|x[1]+x[2] == ZCB->ZCB_IDCNT + ZCB->ZCB_IDLOC })	 > 0
         ZCB->(DbSkip())
         Loop
      Endif
    
      If ZC1->(dbSeek(xFilial("ZC1") + ZCB->ZCB_IDCNT + ZCB->ZCB_IDLOC  ))    //Posiciona na Tabela de contrato para obter o nome da emepresa  

         RecLock(cAliasTRB,.T.) 
         (cAliasTRB)->TIPO:=  	   ZCB->ZCB_TPCONT  
         (cAliasTRB)->CONTRATO:=  	ZC1->ZC1_CODIGO 
         (cAliasTRB)->LOCALIZA:=    ZC1->ZC1_LOCCTR   
         (cAliasTRB)->UNIFICADOR:= 	ZCB->ZCB_IDCNTU    
         (cAliasTRB)->EMPRESA:=  	ZC1->ZC1_RAZSOC          	
         MsUnlock(cAliasTRB)

         Aadd(aCntLoc,{ ZCB->ZCB_IDCNT ,ZCB->ZCB_IDLOC })

      Endif
      ZCB->(DbSkip())
   Enddo 

Endif

RETURN

/*
Função    : VerResM1
Objetivo  : Ajusta a largula dos objetos da pasta Analito/Faturamento
Parametro : Nil
Retorno   : Nil
Autor     : Marcelo Moraes
Data      : 06/12/2019 
Empresa   : CIEE
teste gitlab merge
*/

Static Function VerResM1()

local aRet      := {}
local _aScreens := getScreenRes()

if _aScreens[1] > 1400
   aRet := {30,30}
else
   aRet := {35,65}
endif

return(aRet)


