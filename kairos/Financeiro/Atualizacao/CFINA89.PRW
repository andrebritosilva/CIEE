#Include "TOTVS.ch"
#Include "DBTREE.ch"
#Include 'FWMVCDEF.ch'
#Include "TOPCONN.ch"

/*
Função    : CFINA89
Objetivo  : Tracker Kairos para rastreabilidade a partir do Contas a Pagar
Parametro : Nil
Retorno   : Nil
Autor     : Luiz Enrique de Araujo 
Data      : 22/05/2020
Empresa   : CIEE
*/
User Function CFINA89()

Local aGetArea    := GetArea()
Local aGetAreaSE2 := SE2->(GetArea())
Local aGetAreaZC5 := ZC5->(GetArea())
Local aGetAreaZC1 := ZC1->(GetArea()) 
Local aGetAreaZC4 := ZC4->(GetArea()) 
Local aGetAreaZC3 := ZC3->(GetArea())
Local aGetAreaZC6 := ZC6->(GetArea())
Local aGetAreaZC2 := ZC2->(GetArea())


Begin Sequence

   CFINA89Dialog()

End Sequence

RestArea(aGetAreaZC2)
RestArea(aGetAreaZC3) 
RestArea(aGetAreaZC6)
RestArea(aGetAreaZC4)
RestArea(aGetAreaZC1)
RestArea(aGetAreaZC5)
RestArea(aGetAreaSE2)
RestArea(aGetArea)

Return(Nil)


/*
Função    : CFINA89Dialog
Objetivo  : MSDialog do Tracker Kairos do Contas a Pagar
Parametro : Nil
Retorno   : Nil
Autor     : Luiz Enrique de Araujo
Data      : 22/05/2020
Empresa   : CIEE
*/
Static Function CFINA89Dialog()

Local oDlg
Local aSize, aObjects, aInfo, aPosObj
Local aCoors:= FWGetDialogSize(oMainWnd)	//{0,0,550,1300} 

Local bOk      := {|| oDlg:End()}
Local bCancel  := {|| oDlg:End()}

Local aButtons := {{"BMPVISUAL", {|| CFINA89TView(@oTree)},  "Visualizar"}}

//Objetos
Private oTree
Private oPanelTree
Private oMsMGet     := ""
Private oMsGetDados :=""

Private oPanelView
Private aHeader   := {}
Private aCols	   := {}
Private lexist    := .T.
Private cFileTRB  := ""
Private cAliasTRB := ""

Private cCodIDFOLHA:= ""
Private cCodIDFatur:= ""
Private cCodIDCobra:= ""

/*
If Alltrim(SE2->E2_PREFIXO) <> "PBA" 
   MSGALERT( "Título não é de Bolsa Auxilio!", "Operação Inválida" )
   RETURN
ENDIF
*/

Begin Sequence

   //Definicao das coordenadas para os objetos visuais.
   aSize    := MsAdvSize()

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
   Define MsDialog oDlg Title "Tracker Kairos " +  If(Alltrim(SE2->E2_TIPO) = "PR"," - PROVISÓRIO","") From aCoors[1], aCoors[2] To aCoors[3], aCoors[4] Pixel

   @ 033, 003 MSPanel oPanelTree Prompt "Kairos Tipo: "  + Alltrim(SE2->E2_TIPO)  Colors CLR_BLACK,CLR_WHITE LOWERED RAISED Size 150, 263 Of oDlg
   @ 033, 156 MSPanel oPanelView Prompt "View Tipo: "    + Alltrim(SE2->E2_TIPO)  Colors CLR_BLACK,CLR_WHITE LOWERED RAISED Size 521, 263 Of oDlg

   oTree := dbTree():New(010, 005, 260, 150, oPanelTree,,, .T., .F.,, "Tracker")

   oTree:lShowHint := .T.
   oTree:bChange   := {|| CFINA89TChange(@oTree, @oPanelView, @oMsMGet, @oMsGetDados)}

   Processa({|| CFINA89TLoad(@oTree)}, "Aguarde", "Carregando o Tracking para título tipo: " + Alltrim(SE2->E2_TIPO) , .F.)

   MsAguarde({|| CFINA89TChange(@oTree, @oPanelView, @oMsMGet, @oMsGetDados)}, "Aguarde", "Carregando o Título a Pagar", .F.)

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
Função    : CFINA89TLoad
Objetivo  : Carrega a arvore com a rastreabilidade.
Parametro : oTree : Objeto Tree.
Retorno   : Nil
Autor     : Luiz Enrique de Araujo
Data      : 22/05/2020
Empresa   : CIEE
*/
Static Function CFINA89TLoad(oTree)

LOCAL lSRD:= .f.
LOCAL lzc7:= .f.

Begin Sequence

   oTree:BeginUpdate()
   oTree:Reset()
   oTree:TreeSeek("")

   //Processamento com 8 Tracking 
   ProcRegua(8)

   //Ja Deixa a SRD Posicionada
   SRD->(dbSetOrder(15))   //RC1_FILIAL+RD_XNUMTIT    
   lSRD:= SRD->(dbSeek(xFilial("SRD") + SE2->E2_NUM ))

   //Track 1 -   Adiciona o Título a Pagar - SE2
   oTree:AddItem("Título a Pagar: "+RTrim(SE2->E2_NUM)+" | Prefixo: "+RTrim(SE2->E2_PREFIXO), "SE2"+LTrim(Str(SE2->(Recno()))), "FOLDER10", "FOLDER11",,, 1)

   IncProc()

   // Track 2 - Contrato - Não Provisórios e ou CONTRATOS para os Provisórios 
   //O Titulo quando provisório pode ou não ter movimentos (SRD) e ter contrato - A lógica abaixo, trata estes casos.
   If lSRD
      oTree:AddItem("Contrato", "SRD"+LTrim(Str(SRD->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
   ELSE
      // Track 2 -    Localiza o Contrato - ZC1  - PROVISÁRIOS 
      ZC1->(dbSetOrder(1)) 
      ZC1->(dbSeek(xFilial("ZC1")+SE2->E2_XIDCNT + SE2->E2_XIDLOC))  //Posiciona no Locais de Contratos     
      If ZC1->(Found())
         oTree:AddItem("Contrato: "+RTrim(SE2->E2_XIDCNT )+" | Localizador: "+RTrim(SE2->E2_XIDLOC ), "ZC1"+LTrim(Str(ZC1->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
      Else
         //oTree:AddItem("Contrato: "+RTrim(SE2->E2_XIDCNT )+" | Localizador: "+RTrim(SE2->E2_XIDLOC ), "ZC1"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
         oTree:AddItem("Contrato", "SRD"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      EndIf 
   ENDIF
   IncProc()  

   If Alltrim(SE2->E2_TIPO) == "PR" 
      //Track 3 - Visão Analitica Provisórios
      SRA->(dbSetOrder(28))
      If SRA->(dbSeek(xFilial("SRA")+SE2->E2_XIDCNT  + SE2->E2_XIDLOC ))
         oTree:AddItem("Analitico: Provisórios", "SRA"+LTrim(Str(SRA->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
      ELSE
         oTree:AddItem("Analitico: Provisórios", "SRA"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      ENDIF
      IncProc()

   Endif 

   //Track 4- Folha de bolsa auxílio(Kairós)    
   ZC7->(dbSetOrder(02))
   lzc7:= .F.
   IF ZC7->(dbSeek(xFilial("ZC7")+SE2->E2_XIDCNT  + SE2->E2_XIDLOC ))
      oTree:AddItem("Folha de bolsa auxílio(Kairós)", "ZC7"+LTrim(Str(ZC7->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
      ZC8->(dbSetOrder(01))
      ZC8->(dbSeek(ZC7->ZC7_IDFOL))
      lzc7:= .t.
   ELSE
      oTree:AddItem("Folha de bolsa auxílio(Kairós)", "ZC7"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
   ENDIF
   IncProc()

   /*
   //Track 5- Visão Analitica - Analítico da Folha(Kairós) 
   If lzc7
      ZC8->(dbSetOrder(01))
      IF ZC8->(dbSeek(xFilial("ZC8") + ZC7->ZC7_IDFOL ))
         oTree:AddItem("Analítico da Folha(Kairós)", "ZC8"+LTrim(Str(ZC8->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
      ELSE
         oTree:AddItem("Analítico da Folha(Kairós)", "ZC8"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      ENDIF
      IncProc()
   ENDIF
   */

   // Track 6 -   Configuração da Folha -  ZC2
   ZC2->(dbSetOrder(1))
   ZC2->(dbSeek(xFilial("ZC2") + SRD->RD_XIDFOL))     //Posiciona na configuração da Folha pelo Movimento
   If ZC2->(Found())
      oTree:AddItem("Configuração da Folha: "+RTrim(ZC2->ZC2_IDFOLH), "ZC2"+LTrim(Str(ZC2->(Recno()))), "FOLDER10", "FOLDER11",,, 1)   
   Else
      ZC2->(dbSetOrder(2)) 
      ZC2->(dbSeek(xFilial("ZC2")+SE2->E2_XIDCNT ))   //Posiciona na configuração da Folha pelo contrato  
      If ZC2->(Found())
         oTree:AddItem("Configuração da Folha: "+RTrim(ZC2->ZC2_IDFOLH), "ZC2"+LTrim(Str(ZC2->(Recno()))), "FOLDER10", "FOLDER11",,, 1)   
      Else
         oTree:AddItem("Configuração da Folha:", "ZC2"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      Endif
   EndIf 
   cCodIDFOLHA:= RTrim(ZC2->ZC2_IDFOLH)
   IncProc()

   //Track 7 Configuração de Cobrança - ZC3
   FTabConfig (2,SE2->E2_XIDCNT,oTree)

   //Track 8 Configuração do Faturamento - ZC4 
   FTabConfig (1,SE2->E2_XIDCNT,oTree)

   oTree:EndUpdate()
   oTree:Refresh()

End Sequence

Return(Nil)                           

/*
Função    : CFINA89TChange
Objetivo  : Função chamada na mudança de posição do item do Tree.
Parametro : oTree       : Objeto Tree.
            oPanelView  : Objeto Panel.
            oMsMGet     : Objeto MsMGet.
            oMsGetDados : Objeto oMsGetDados.
Retorno   : .T.
Autor     : Luiz Enrique de Araujo
Data      : 22/05/2020
Empresa   : CIEE
*/

Static Function CFINA89TChange(oTree, oPanelView, oMsMGet, oMsGetDados)

Local cAlias
//Local cSeek    
//Local bWhile   
//Local cAliasD  
//Local nOrderD  

Local nRecno
Local lFound
//Local oStruAlias
//Local aSize   := {}  

Local oFWLayer
Local oRelation
Local oRelatSra
//Local oRelatSZ2
Local oRelatSZ3
Local oRelatSZ4
Local oRelatSZ8

Local oPanelUp
Local omBrowseUP
Local oPanelMeio
Local omBrowseMeio
Local oPanelDown
Local omBrowseDown
//Local oPanelDow2
Local omBrowseD2
//Local lTemContrato:= .t.

Private aRotina:={}
Private aCampos:={} 
//Private Acolun1:={}
Private Acolun2:={}

//aAdd( Acolun1 , { "TIPO"      , "TIPO"       , "C" , 01 , 0 , "@!" } ) 
//aAdd( Acolun1 , { "CONTRATO"  , "CONTRATO"   , "C" , 15 , 0 , "@!" } ) 
//aAdd( Acolun1 , { "UNIFICADOR", "UNIFICADOR" , "C" , 15 , 0 , "@!" } ) 
//aAdd( Acolun1 , { "EMPRESA"   , "EMPRESA"    , "C" , 150, 0 , "@!" } ) 

//aAdd( Acolun2 , { "TIPO"      , "TIPO"       , "C" , 01 , 0 , "@!" } ) 
aAdd( Acolun2 , { "CONTRATO"  , "CONTRATO"   , "C" , 15 , 0 , "@!" } ) 
aAdd( Acolun2 , { "LOCAL"     , "LOCALIZA"   , "C" , 15 , 0 , "@!" } ) 
aAdd( Acolun2 , { "UNIFICADOR", "UNIFICADOR" , "C" , 15 , 0 , "@!" } ) 
aAdd( Acolun2 , { "EMPRESA"   , "EMPRESA"    , "C" , 150, 0 , "@!" } ) 

CursorWait()

Begin Sequence

   cAlias := Left(oTree:GetCargo(), 3)
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

   Do Case

      Case  cAlias == "SRD" .OR. ;  //PARA CONTRATOS NORMAIS 
            cAlias == "SRA" .OR. ;  //Analitico para os Provisórios
            cAlias == "ZC1" .OR. ;  //PARA CONTRATOS PROVISORIO
            cAlias == "ZC2" .OR. ;  //Configuração da Folha 
            cAlias == "ZC3" .OR. ;  //Configuração de Cobrança
            cAlias == "ZC4" .OR. ;  //Configuração do Faturamento
            cAlias == "ZC7"         //FOLHA BOLSA AUXILIO - Sintético e Analitico

         AtualizaTRB(cAlias )  // Monta arquivo temporario conforme Titulo em questão.

         If cAlias <> "ZC7" .AND. (cAliasTRB)->(Eof()) 
            InfoMsget(cAlias,nRecno)    ////GETDADOS PARA VISUALIZAÇÕES GENERICAS A PARTIR DO ALIAS INFORMADO - Não possui contratos
            BREAK
         Endif

         If cAlias == "SRD" .Or. cAlias == "ZC1"   //CONTRATOS NORMAIS OU PROVISORIOS
                 
            //LISTA DOS CONTRATOS (TEMPORARIO)
            oFWLayer := FWLayer():New()
            oFWLayer:Init( oPanelView, .F., .T. )
            oFWLayer:addLine( 'UP', 50, .F. )
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

            omBrowseUP:SetDescription('Contrato: ' +  Alltrim(SE2->E2_XIDCNT))
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
            oFWLayer:addLine( 'MEIO',50, .F. )
            oPanelMeio:= oFWLayer:getLinePanel('MEIO')
            omBrowseMeio:= FWMBrowse():New()
            omBrowseMeio:SetAlias('ZC1')
            omBrowseMeio:SetDescription('Local de Contrato: ' + Alltrim(SE2->E2_XIDLOC) )
            omBrowseMeio:DisableDetails()
            omBrowseMeio:SetProfileID("2")
            omBrowseMeio:SetOwner( oPanelMeio )
            omBrowseMeio:SetIgnoreARotina( .T.)
            omBrowseMeio:SetMenuDef("")
            omBrowseMeio:AddButton('Ver Local', 'AxVisual', , 4, 0)  
            omBrowseMeio:Activate()

            oRelation := FWBrwRelation():New()
            oRelation:AddRelation( omBrowseUP, omBrowseMeio, {    {'ZC1->ZC1_FILIAL','xFilial( "ZC1" )' } ,;
                                                                  {'ZC1->ZC1_CODIGO','(cAliasTRB)->CONTRATO','==' },;
                                                                  {'ZC1->ZC1_LOCCTR','(cAliasTRB)->LOCALIZA','==' }} )
            oRelation:Activate()

         ENDIF
      
         If cAlias == "SRA"    // Analitico para os Provisórios

             //LISTA DOS CONTRATOS (TEMPORARIO)
            oFWLayer := FWLayer():New()
            oFWLayer:Init( oPanelView, .F., .T. )
            oFWLayer:addLine( 'UP', 50, .F. )
            oPanelUp := oFWLayer:getLinePanel('UP')

            omBrowseUP:= FWMBrowse():New()
            omBrowseUP:SetAlias(cAliasTRB)
            omBrowseUP:SetFields(Acolun2)      
            omBrowseUP:SetTemporary(.T.)
            omBrowseUP:SetDescription('Contrato: ' + Alltrim(SE2->E2_XIDCNT) + " - Local: " + Alltrim(SE2->E2_XIDLOC) )
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
            omBrowseDown:SetAlias('SRA')
            omBrowseDown:SetDescription('Analitico dos Provisórios:')
            omBrowseDown:DisableDetails()
            omBrowseDown:SetAmbiente(.T.)
            omBrowseDown:SetUseFilter(.T.)
            //omBrowseDown:SetFilterDefault("RA_FILIAL+RA_XIDCONT+RA_XIDLOCT == xFilial('SRA') + (cAliasTRB)->CONTRATO + (cAliasTRB)->LOCALIZA ")
            omBrowseDown:SetProfileID("2")
            omBrowseDown:SetOwner( oPanelDown )
            omBrowseDown:SetIgnoreARotina( .T.)
            //omBrowseDown:SetMenuDef("CFINA89E")
            omBrowseDown:SetMenuDef("")
            omBrowseDown:AddButton('Visualizar', 'AxVisual', , 4, 0)  
            omBrowseDown:Activate()

            oRelatSra:= FWBrwRelation():New()
            oRelatSra:AddRelation( omBrowseUP, omBrowseDown, {  {'SRA->RA_FILIAL','xFilial( "SRA" )' } ,;
                                                                {'SRA->RA_XIDCONT','(cAliasTRB)->CONTRATO','==' },;
                                                                {'SRA->RA_XIDLOCT','(cAliasTRB)->LOCALIZA','==' }} )
            oRelatSra:Activate()

         ENDIF

         If  cAlias == "ZC7"    //FOLHA BOLSA AUXILIO - Sintético e Analitico

            oFWLayer:= FWLayer():New()
            oFWLayer:Init( oPanelView, .F., .T. )
            oFWLayer:addLine( 'UP', 40, .F. )
            oPanelUP:= oFWLayer:getLinePanel('UP')

            omBrowseDown:= FWMBrowse():New()
            omBrowseDown:SetAlias('ZC7')
            omBrowseDown:SetDescription('Sintético Bolsa Auxilio:')
            omBrowseDown:DisableDetails()
            //omBrowseDown:SetFilterDefault("ZC7_IDCNTT+ZC7_IDLOCC == SE2->E2_XIDCNT + SE2->E2_XIDLOC ")
            omBrowseDown:SetFilterDefault("ZC7_IDCNTT == SE2->E2_XIDCNT")
            omBrowseDown:SetProfileID("1")
            omBrowseDown:SetOwner(oPanelUP)
            omBrowseDown:SetIgnoreARotina( .T.)
            //omBrowseDown:SetMenuDef("CFINA89C")
            omBrowseDown:SetMenuDef("")
            omBrowseDown:AddButton('Visualizar', 'AxVisual', , 4, 0) 
            omBrowseDown:Activate()

            /*
            oRelatSZ7:= FWBrwRelation():New()
            oRelatSZ7:AddRelation( omBrowseDown, omBrowseMeio, {  {'ZC7->ZC7_FILIAL','xFilial( "ZC7" )' } ,;
                                                                  {'ZC7->ZC7_IDCNTT','ZC1->ZC1_CODIGO','==' },;
                                                                  {'ZC7->ZC7_IDLOCC','ZC1->ZC1_LOCCTR','==' }} )
            oRelatSZ7:Activate()
            */

            oFWLayer:addLine( 'DOWN', 60, .F. )
            oPanelDow:= oFWLayer:getLinePanel('DOWN')
            omBrowseD2:= FWMBrowse():New()
            omBrowseD2:SetAlias('ZC8')
            omBrowseD2:SetDescription('Analitico Bolsa Auxilio:')
            omBrowseD2:DisableDetails()
            omBrowseD2:SetProfileID("2")
            omBrowseD2:SetOwner(oPanelDow)
            omBrowseD2:SetIgnoreARotina( .T.)
            //omBrowseD2:SetMenuDef("CFINA89D")
            omBrowseD2:SetMenuDef("")
            omBrowseD2:AddButton('Visualizar', 'AxVisual', , 4, 0) 
            omBrowseD2:Activate()

            oRelatSZ8:= FWBrwRelation():New()
            /* A CHAVE DE INDICE 1 DA ZC8 ESTA FALTANDO A FILIAL
            oRelatSZ8:AddRelation( omBrowseDown, omBrowseD2, { {'ZC8->ZC8_FILIAL','xFilial( "ZC8" )' } ,;
                                                               {'ZC8->ZC8_IDFOL','ZC7->ZC7_IDFOL','==' }} )

            */
            oRelatSZ8:AddRelation( omBrowseDown, omBrowseD2, { {'ZC8->ZC8_IDFOL','ZC7->ZC7_IDFOL','==' }} )
            oRelatSZ8:Activate()
            
         
         ENDIF

         If  cAlias == "ZC2"    //Configuração da Folha 

            oFWLayer := FWLayer():New()
            oFWLayer:Init( oPanelView, .F., .T. )
            oFWLayer:addLine( 'UP', 50, .F. )
            oPanelUp := oFWLayer:getLinePanel('UP')

            omBrowseUP:= FWMBrowse():New()
            omBrowseUP:SetAlias(cAliasTRB)
            omBrowseUP:SetFields(Acolun2)      
            omBrowseUP:SetTemporary(.T.)
            omBrowseUP:SetDescription('Contrato: ' + Alltrim(SE2->E2_XIDCNT) + " - Local: " + Alltrim(SE2->E2_XIDLOC) )
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
            omBrowseDown:SetAlias('ZC2')
            omBrowseDown:SetDescription('Configuração da Folha: ' + cCodIDFOLHA)
            omBrowseDown:DisableDetails()
            //omBrowseDown:SetFilterDefault("ZC7_IDCNTT+ZC7_IDLOCC == SE2->E2_XIDCNT + SE2->E2_XIDLOC ")
            omBrowseDown:SetProfileID("2")
            omBrowseDown:SetOwner( oPanelDown )
            omBrowseDown:SetIgnoreARotina( .T.)
            //omBrowseDown:SetMenuDef("CFINA89C")
            omBrowseDown:SetMenuDef("")
            omBrowseDown:AddButton('Visualizar', 'AxVisual', , 4, 0) 
            omBrowseDown:Activate()

            oRelatSZ3:= FWBrwRelation():New()
            oRelatSZ3:AddRelation( omBrowseUP, omBrowseDown,   {  {'ZC2->ZC2_FILIAL','xFilial( "ZC2" )' } ,;
                                                                  {'ZC2->ZC2_IDCONT','(cAliasTRB)->CONTRATO','==' }} )
            oRelatSZ3:Activate()

         ENDIF

         If  cAlias == "ZC3"    //Configuração de Cobrança

            oFWLayer := FWLayer():New()
            oFWLayer:Init( oPanelView, .F., .T. )
            oFWLayer:addLine( 'UP', 50, .F. )
            oPanelUp := oFWLayer:getLinePanel('UP')

            omBrowseUP:= FWMBrowse():New()
            omBrowseUP:SetAlias(cAliasTRB)
            omBrowseUP:SetFields(Acolun2)      
            omBrowseUP:SetTemporary(.T.)
            omBrowseUP:SetDescription('Contrato: ' + Alltrim(SE2->E2_XIDCNT) + " - Local: " + Alltrim(SE2->E2_XIDLOC) )
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
            omBrowseDown:SetProfileID("2")
            omBrowseDown:SetOwner( oPanelDown )
            omBrowseDown:SetIgnoreARotina( .T.)
            //omBrowseDown:SetMenuDef("CFINA89C")
            omBrowseDown:SetMenuDef("")
            omBrowseDown:AddButton('Visualizar', 'AxVisual', , 4, 0) 
            omBrowseDown:Activate()

            oRelatSZ3:= FWBrwRelation():New()
            oRelatSZ3:AddRelation( omBrowseUP, omBrowseDown,   {  {'ZC3->ZC3_FILIAL','xFilial( "ZC3" )' } ,;
                                                                  {'ZC3->ZC3_IDCONT','(cAliasTRB)->CONTRATO','==' }} )
                                                                  //,;{'ZC3->ZC3_LOCCTR','(cAliasTRB)->LOCALIZA','==' }
            oRelatSZ3:Activate()

         ENDIF

         If  cAlias == "ZC4"    //Configuração do Faturamento

            oFWLayer := FWLayer():New()
            oFWLayer:Init( oPanelView, .F., .T. )
            oFWLayer:addLine( 'UP', 50, .F. )
            oPanelUp := oFWLayer:getLinePanel('UP')

            omBrowseUP:= FWMBrowse():New()
            omBrowseUP:SetAlias(cAliasTRB)
            omBrowseUP:SetFields(Acolun2)      
            omBrowseUP:SetTemporary(.T.)
            omBrowseUP:SetDescription('Contrato: ' + Alltrim(SE2->E2_XIDCNT) + " - Local: " + Alltrim(SE2->E2_XIDLOC) )
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
            omBrowseDown:SetDescription('Configuração do Faturamento: ' + cCodIDFatur)
            omBrowseDown:DisableDetails()
            //omBrowseDown:SetFilterDefault("ZC7_IDCNTT+ZC7_IDLOCC == SE2->E2_XIDCNT + SE2->E2_XIDLOC ")
            omBrowseDown:SetProfileID("2")
            omBrowseDown:SetOwner( oPanelDown )
            omBrowseDown:SetIgnoreARotina( .T.)
            //omBrowseDown:SetMenuDef("CFINA89C")
            omBrowseDown:SetMenuDef("")
            omBrowseDown:AddButton('Visualizar', 'AxVisual', , 4, 0) 
            omBrowseDown:Activate()

            oRelatSZ4:= FWBrwRelation():New()
            oRelatSZ4:AddRelation( omBrowseUP, omBrowseDown, {  {'ZC4->ZC4_FILIAL','xFilial( "ZC4" )' } ,;
                                                                {'ZC4->ZC4_IDCONT','(cAliasTRB)->CONTRATO','==' }} )
            oRelatSZ4:Activate()
         
         ENDIF

      Otherwise

         InfoMsget(cAlias,nRecno)    //GETDADOS PARA VISUALIZAÇÕES GENERICAS A PARTIR DO ALIAS INFORMADO 

   End Case

End Sequence

oPanelView:Refresh()

CursorArrow()

Return(.T.)

/*/{Protheus.doc} InfoMsget
Mostra informação do Tracker apenas pela GETDADOS
@type  Static Function
@author Luiz Enrique
@since 02/07/2020
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
Static Function InfoMsget(cAlias,nRecno)

Local aAcho := {}
Local nPos  := 0

//GETDADOS PARA VISUALIZAÇÕES GENERICAS A PARTIR DO ALIAS INFORMADO
dbSelectArea(cAlias)
(cAlias)->(dbGoTo(nRecno))
oPanelView:FreeChildren()              //Elimina (libera) todos os objetos da classe oPanel.
oStruAlias:= FWFormStruct(1, cAlias)   //Carrega as propriedades para o objeto oMsMGet.

For nPos := 1 To Len(oStruAlias:aFields)
   Aadd(aAcho, AllTrim(oStruAlias:aFields[nPos, MODEL_FIELD_IDFIELD]))
Next

aSize := {10, 5, 260, 519}

RegToMemory(cAlias, .F., .F., .F.)   
oMsMGet := MsMGet():New(cAlias, (cAlias)->(Recno()), 2, , , , aAcho, aSize, , 3, , , , oPanelView, .F., .T., .F.,,, .T.)
oMsMGet:Refresh()
  
Return 

Static Function MenuDef()   

Local aRotGrp := {}

ADD OPTION aRotGrp TITLE "Pesquisar"		ACTION "PesqBrw"         OPERATION 1 ACCESS 0 DISABLE MENU
ADD OPTION aRotGrp TITLE "Visualizar"		ACTION "VIEWDEF.CFINA89" OPERATION 2 ACCESS 0
//ADD OPTION aRotGrp TITLE "Incluir"		ACTION "VIEWDEF.CFINA89" OPERATION 3 ACCESS 0
//ADD OPTION aRotGrp TITLE "Alterar"		ACTION "VIEWDEF.CFINA89" OPERATION 4 ACCESS 143
//ADD OPTION aRotGrp TITLE "Excluir"		ACTION "VIEWDEF.CFINA89" OPERATION 5 ACCESS 144
ADD OPTION aRotGrp TITLE "Imprimir"			ACTION "VIEWDEF.CFINA89" OPERATION 8 ACCESS 0

Return aRotGrp


Static Function ModelDef()  

Local oStruZC1 := Nil
Local oModContrato := Nil

oStruZC1 := FWFormStruct(1,"ZC1")

oModContrato:= MPFormModel():New("LOCCONT",/*{ |oModContrato| /*PreVldMdl( oModContrato ) }*/,/* }*/,/* }*/,/*Cancel*/)  
oModContrato:AddFields("LOCCONT_CAB", Nil/*cOwner*/, oStruZC1 ,/*{||VldGRUP(oModContrato)}*/,,/*Carga*/)
oModContrato:GetModel("LOCCONT_CAB"):SetDescription("Locais")
oModContrato:SetPrimaryKey({"ZC1_FILIAL","ZC1_CODIGO","ZC1_LOCCTR"})
                                                                               
Return(oModContrato)

//-------------------------------------------------------------------
Static Function ViewDef()

Local oStruZC1 := FWFormStruct(2,"ZC1")
Local oModContrato:= FWLoadModel( 'CFINA89' )
Local oView

oView := FWFormView():New()
//oView:SetUseCursor(.F.)
oView:SetModel(oModContrato)
oView:AddField( "LOCCONT_CAB",oStruZC1)
oView:CreateHorizontalBox("GERAL",100)
//oView:CreateVerticalBox( 'DIREITO',100, 'DIREITO' )
oView:SetOwnerView( "LOCCONT_CAB","GERAL")
oView:EnableControlBar(.T.)

Return oView 


/*/{Protheus.doc} FNOMEMATRI()
   Mostra o Nome do FUNCIONARIO da SRD pois o campo do nome na SRD esta como Virtual e não aparece na Getdados (Hooo dó)
   @type  Static Function
   @author Luiz Enrique
   @since 11/06/2020
   @version version
   @param param_name, param_type, param_descr
   @return return_var, return_type, return_description
   @example
   (examples)
   @see (links_or_references)
   /*/
/*Static Function FNOMEMATRI(cAliasD)

Local nx:= 0
Local cMatricula:= ""
Local nPnome:= aScan(aHeader,{|x| AllTrim(x[2])== "RD_XNOME"})
Local nPmatr:= aScan(aHeader,{|x| AllTrim(x[2])== "RD_MAT"})

IF cAliasD == "SRD"
   SRA->(dbSetOrder(1))
   For nx:= 1 to Len(Acols)
      If Empty(Acols [nx] [nPnome])        
         cMatricula:=  Padr(aCols[nx] [nPmatr],TamSx3("RA_MAT")[1])
         If SRA->(dbSeek( xFilial("SRA")+ cMatricula))
            aCols[nx] [nPnome]:= SRA->RA_NOME
         ENDIF
      ENDIF
   Next  
ENDIF
   
Return*/


/*
Função    : CFINA89TView
Objetivo  : Visualização do Cadastro Original da tabela.
Parametro : oTree : Objeto Tree.
Retorno   : Nil
Autor     : Luiz Enrique de Araujo
Data      : 12/12/2019
Empresa   : CIEE
*/

Static Function CFINA89TView(oTree)

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

      CASE cAlias == "SRD"
      
         //A410Visual("SRD", SRD->(Recno()), 2)
         Break

      Case cAlias == "SE2"
         cTitulo   := "Contas a Pagar"
         cPrograma := "XFA280View"  //"FinA040"  //FA280Visua

         FA280Visua("SE2", SE2->(Recno()), 2)
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

       Case cAlias == "SRA"
         cTitulo   := "Bolsa Auxilio"
         cPrograma := "CFINA89E"

      Case cAlias == "SC5"
         cTitulo   := "Pedido de Venda"
         cPrograma := "MATA410"

         A410Visual("SC5", SC5->(Recno()), 2)
         Break
      Otherwise
         MsgAlert(cAlias, "Sem Visualização")
         Break

   End Case

   FWExecView("Tracker Kairos - "+cTitulo , cPrograma, MODEL_OPERATION_VIEW,, {|| .T.}, {|| .T.}, 40,, {|| .T.},,,)

End Sequence

Return(Nil)

/*/{Protheus.doc} FTabConfig
Localiza e Posiciona  em:
nOP = 1 - Tabela de Configuração do Faturamento - ZC4 
nOP = 2 - Tabela de Configuração de Cobrança - ZC3
@type  Static Function
@author Luiz Enrique de Araujo
@since 11/06/2020
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
Static Function FTabConfig (nop,cXIDCNT,oTree)

Local cXquery:= ""

DO CASE

   CASE nOP ==  1    //Configuração do Faturamento - ZC4 
     
      cXquery:=" SELECT ZC4.R_E_C_N_O_ AS RECNOZC4"
      cXquery+=" FROM " + RetSqlName("ZC4") + " ZC4" 
      cXquery+=" WHERE ZC4_FILIAL ='" + xFilial("ZC4") + "'"
      cXquery+=" AND ZC4.D_E_L_E_T_=''"
      cXquery+=" AND ZC4_IDCONT = '" + cXIDCNT + "'"
      cXquery+=" AND ZC4_STATUS = '1' "

      IF SELECT("TMP") > 0
         TMP->(dbCloseArea())
      Endif 
                  
      TCQUERY cXQuery NEW ALIAS TMP  
                  
      If TMP->(!Eof()) .AND. !Empty(TMP->RECNOZC4)
         ZC4->(DBGOTO( TMP->RECNOZC4 ))
         oTree:AddItem("Configuração da Fatura: "+RTrim(ZC4->ZC4_IDFATU), "ZC4"+LTrim(Str(ZC4->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
      ELSE
         oTree:AddItem("Configuração da Fatura: "+RTrim(""), "ZC4"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      ENDIF
      cCodIDFatur:= RTrim(ZC4->ZC4_IDFATU)

   CASE nOp == 2     //Configuração de Cobrança - ZC3

      cXquery:=" SELECT ZC3.R_E_C_N_O_ AS RECNOZC3"
      cXquery+=" FROM " + RetSqlName("ZC3") + " ZC3" 
      cXquery+=" WHERE ZC3_FILIAL ='" + xFilial("ZC3") + "'"
      cXquery+=" AND ZC3.D_E_L_E_T_=''"
      cXquery+=" AND ZC3_IDCONT = '" + cXIDCNT + "'"
      cXquery+=" AND ZC3_STATUS = '1' "

      IF SELECT("TMP") > 0
         TMP->(dbCloseArea())
      Endif 
                  
      TCQUERY cXQuery NEW ALIAS TMP  
                  
      If TMP->(!Eof()) .AND. !Empty(TMP->RECNOZC3)
         ZC3->(DBGOTO( TMP->RECNOZC3 ))
         oTree:AddItem("Configuração da Cobrança: "+RTrim(ZC3->ZC3_IDCOBR), "ZC3"+LTrim(Str(ZC3->(Recno()))), "FOLDER10", "FOLDER11",,, 1)
      ELSE
         oTree:AddItem("Configuração da Cobrança: "+RTrim(cXIDCNT), "ZC3"+LTrim(Str(0)), "FOLDER7", "FOLDER8",,, 1)
      ENDIF
      cCodIDCobra:= RTrim(ZC3->ZC3_IDCOBR)
         
ENDCASE

TMP->(dbCloseArea())

IncProc()
   
Return 

/*/{Protheus.doc} User Function FI89VERCT
Mostra as informações do Contrato em questao
@type  Function
@author Luiz Enrique de Araujo
@since 24/06/2020
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function FI89VERCT()

Local aArea := GetArea()

DBSELECTAREA("ZC0")

ZC0->(DBSetOrder(1))

If ZC0->(dbSeek(xFilial("ZC0") + (cAliasTRB)->CONTRATO)) 
   ZC0->(AxVisual('ZC0',ZC0->(Recno()),2))
ENDIF

RestArea(aArea)
  
Return 


//----------------------------------------------------------------------------------
/*{Protheus.doc} CriaTRB1
Cria Tabela Temporaria (Estrutura) para as APRESENTAÇÃO dos Contratos dos Titulos Provisórios e Normais
Considerando o conceito de contrato unificado que pode ou não existir
@author Luiz Enrique de Araujo
@since 22/06/2020
@project  
/*/   
//-----------------------------------------------------------------------------------
/*Static Function CriaTRB1()

aCampos := {} 

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
@since 22/06/2020
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

Return

//----------------------------------------------------------------------------------
/*{Protheus.doc} AtualizaTRB
Monta Lista dos Contratos a serem msotrados no Browse ou utilizados como Filtro para demais visualizações
@author Luiz Enrique de Araujo
@since 22/06/2020
@project  
/*/   
//-----------------------------------------------------------------------------------
Static Function AtualizaTRB(cAlias)

Local aCntLoc:= {}

ZC0->(DBSetOrder(1))
ZC1->(DBSetOrder(1))
ZCB->(DBSetOrder(2)) //ZCB_FILIAL + ZCB_IDCNTU
ZCI->(DBSetOrder(2)) //ZCI_FILIAL + ZCI_IDUNIF

//If  cAlias == "SRD" .Or. cAlias == "ZC1" //Painel dos Contratos
 //  CriaTRB1()
//else
   CriaTRB2()
//Endif

If cAlias == "SRD"    //Contratos Normais  - UNIFICADOR PELA ZCI

   While SRD->(!EOF()) .and. SRD->RD_FILIAL == Xfilial("SRD") .and. SRD->RD_XNUMTIT  == SE2->E2_NUM 

      If AsCan(aCntLoc,{|x|x[1]+x[2] == SRD->RD_XIDCNT + SRD->RD_XIDLOC  }) > 0
         SRD->(DbSkip())
         Loop
      Endif

      If  ZCI->(DBSeek(Xfilial("ZCI") + SRD->RD_XIDCNT ))       //Posiciona na Tabela de Contratos Unificado
         
         If ZC1->(dbSeek(xFilial("ZC1") + SRD->RD_XIDCNT + SRD->RD_XIDLOC  ))    //Posiciona na Tabela de contrato para obter o nome da emepresa                                   
            RecLock(cAliasTRB,.T.) 
            (cAliasTRB)->TIPO:=  	   ZCI->ZCI_TPCONT  
            (cAliasTRB)->CONTRATO:=  	ZC1->ZC1_CODIGO 
            (cAliasTRB)->LOCALIZA:=    ZC1->ZC1_LOCCTR     
            (cAliasTRB)->UNIFICADOR:= 	ZCI->ZCI_IDUNIF  
            (cAliasTRB)->EMPRESA:=  	ZC1->ZC1_RAZSOC          	
            MsUnlock(cAliasTRB)

            Aadd(aCntLoc,{ SRD->RD_XIDCNT,SRD->RD_XIDLOC })
         Endif
      Endif
      SRD->(DbSkip())
   Enddo

Elseif   cAlias == "ZC1"   //Contratos dos Provisórios  - UNIFICADOR PELA ZCI

         ZCI->(DBSetOrder(3))    //ZCI_FILIAL+ZCI_IDCONT+ZCI_LOCCTR 

         If ZCI->(DBSeek(Xfilial("ZCI") + SE2->E2_XIDCNT + SE2->E2_XIDLOC  )) 

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
            If ZC1->(dbSeek(xFilial("ZC1") + SE2->E2_XIDCNT + SE2->E2_XIDLOC  ))    //Posiciona na Tabela de contrato para obter o nome da emepresa                                      
               RecLock(cAliasTRB,.T.) 
               (cAliasTRB)->TIPO:=  	   "1"  
               (cAliasTRB)->CONTRATO:=  	SE2->E2_XIDCNT
               (cAliasTRB)->LOCALIZA:=    SE2->E2_XIDLOC
               (cAliasTRB)->UNIFICADOR:= 	SE2->E2_XIDCNT   
               (cAliasTRB)->EMPRESA:=  	ZC1->ZC1_RAZSOC          	
               MsUnlock(cAliasTRB)	
            Endif   
         Endif 

Elseif   cAlias == "ZC3" .Or.;   //Configuração de Cobrança 
         cAlias == "ZC4" .Or.;   //Configuração do Faturamento
         cAlias == "SRA"         //Analitico para os Provisórios

         ZCI->(DBSeek(Xfilial("ZCI") + SE2->E2_XIDCNT ))  

         While ZCI->(!EOF()) .and. ZCI->ZCI_FILIAL == SE2->E2_FILIAL .and. ZCI->ZCI_IDUNIF  == SE2->E2_XIDCNT

            If AsCan(aCntLoc,{|x|x[1]+x[2] == ZCI->ZCI_IDCONT + ZCI->ZCI_LOCCTR })	 > 0
               ZCI->(DbSkip())
               Loop
            Endif

            If ZC1->(dbSeek(xFilial("ZC1") + ZCI->ZCI_IDCONT + ZCI->ZCI_LOCCTR ))    //Posiciona na Tabela de contrato para obter o nome da emepresa   
                                          
               RecLock(cAliasTRB,.T.) 
               (cAliasTRB)->TIPO:=  	   ZCI->ZCI_TPCONT  
               (cAliasTRB)->CONTRATO:=  	ZC1->ZC1_CODIGO 
               (cAliasTRB)->LOCALIZA:=    ZC1->ZC1_LOCCTR  
               (cAliasTRB)->UNIFICADOR:= 	ZCI->ZCI_IDUNIF    
               (cAliasTRB)->EMPRESA:=  	ZC1->ZC1_RAZSOC          	
               MsUnlock(cAliasTRB)	

               Aadd(aCntLoc,{ ZCI->ZCI_IDCONT,ZCI->ZCI_LOCCTR })

            Endif
            ZCI->(DbSkip())
         Enddo
     
ElseIf cAlias == "ZC2"   //Configuração da Folha   - UNIFICADOR PELA ZCB

      ZCB->(DBSeek(Xfilial("ZCB") + SE2->E2_XIDCNT ))       //Posiciona na Tabela de Contratos Unificado
         
      While ZCB->(!EOF()) .and. ZCB->ZCB_FILIAL == SE2->E2_FILIAL .and. ZCB->ZCB_IDCNTU  == SE2->E2_XIDCNT

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
