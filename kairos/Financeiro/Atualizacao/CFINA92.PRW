#INCLUDE 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"


Static lMarkAll := .T.

/*/{Protheus.doc} CFINA92
Monitor SPBA - Financeiro
@type  Function
@author Carlos Henrique
@since 05/03/2020
@version version
/*/
User Function CFINA92()
    Local oBrowse := FwMBrowse():New()

    oBrowse:SetAlias("RC1")
    oBrowse:SetDescription("Monitor SPBA - Financeiro")
    oBrowse:AddLegend("RC1_INTEGR=='0'", "BR_AMARELO"	, "Pendente geração do CNAB")
    oBrowse:AddLegend("RC1_INTEGR=='1'", "BR_CINZA"  	, "Falha na geração do CNAB")
    oBrowse:AddLegend("RC1_INTEGR=='2'", "BR_BRANCO"  	, "Pendente de liberação de pagamento")
    oBrowse:AddLegend("RC1_INTEGR=='3'", "BR_LARANJA"  	, "Em aprovação Fluig"  )
    oBrowse:AddLegend("RC1_INTEGR=='4'", "BR_VERDE"  	, "Aprovado"  )
    oBrowse:AddLegend("RC1_INTEGR=='5'", "BR_VERMELHO"  , "Reprovado"  )
    oBrowse:AddLegend("RC1_INTEGR=='6'", "BR_AZUL"  	, "Finalizado"  )
    oBrowse:SetFilterDefault("ALLTRIM(RC1_NATURE)!='IRF'") //Não Listar titulos de IR
    oBrowse:Activate()

RETURN
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina de definição do menu
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17
@return   	Nenhum
/*/
// //---------------------------------------------------------------------------------------
Static Function MenuDef()
    Local aRotina := {}

    ADD OPTION aRotina TITLE "Visualizar"                       ACTION "VIEWDEF.CFINA92"    OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE "Gerar CNAB"                       ACTION "U_CJOBK03(.F.)"     OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE "Gerar CNAB Clientes"              ACTION "U_CFIN92CNABEX"     OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE "Liberar para pagamento"           ACTION "U_C06A92LP"         OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE "CNAB Inconsistencias"             ACTION "U_CFINA94"          OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE "Relatório de Inconsistencias"     ACTION "U_CFINR81('')"      OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE "Relatório sintético BA/Pensao"    ACTION "U_C06A92RS()"       OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE "CNAB Validação Bancária"          ACTION "U_CJOBK12"          OPERATION 5 ACCESS 0
    ADD OPTION aRotina TITLE "CNAB Pensão"                      ACTION "U_CJOBK03(.T.)"     OPERATION 6 ACCESS 0

Return(aRotina)
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina de definição do MODEL
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function ModelDef()
    Local oStruCAB 	:= FWFormStruct(1, "RC1")
    Local oModel   	:= MPFormModel():New( 'C6A92MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

    oModel:AddFields("RC1MASTER", /*cOwner*/, oStruCAB)
    oModel:SetPrimaryKey({"RC1_FILIAL","RC1_NUMTIT"})
    oModel:SetDescription("Monitor SPBA - Financeiro")
    oModel:getModel("RC1MASTER"):SetDescription("Financeiro")

Return oModel
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina de definição do VIEW
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function ViewDef()
    Local oView    	:= FWFormView():New()
    Local oStruCAB 	:= FWFormStruct(2,"RC1")
    Local oModel   	:= FWLoadModel("CFINA92")

    oView:SetModel(oModel)
    oView:AddField("VIEW_CAB", oStruCAB, "RC1MASTER")

    oView:CreateHorizontalBox("SUPERIOR", 100)

    oView:SetOwnerView("VIEW_CAB", "SUPERIOR")

Return oView

/*/{Protheus.doc} C06A92LP
Rotina de liberação de pagamento
@author Carlos Henrique
@since 27/04/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function C06A92LP()
    Local aParam:= {}
    Local aRet	:= {}
    Local lOk	:= .F.
    Local aTitSt:= {}
    Local aAdvSize:= {}
    Local nCnta := 0
    Local oOk	:= LoadBitmap( GetResources(), "LBTIK" )	//CHECKED    //LBOK  //LBTIK
    Local oNo	:= LoadBitmap( GetResources(), "LBNO" ) 	//UNCHECKED  //LBNO
    Local cPictVrl:= PESQPICT("RC1","RC1_VALOR")
    Local cFiltro:= ""
    local cRet   := ""

    aAdd(aParam,{1,"Venc. De"		, CTOD(''),"","","","",50,.T.})
    aAdd(aParam,{1,"Venc. Até"		, CTOD(''),"","","","",50,.T.})
    aAdd(aParam,{1,"Filial De"		, Space(TamSx3('RC1_FILTIT')[1])	,"","","SM0"	,"",0,.F.})
    aAdd(aParam,{1,"Filial Até"		, Space(TamSx3('RC1_FILTIT')[1])	,"","","SM0"	,"",0,.F.})
    aAdd(aParam,{1,"Fornecedor De"	, Space(TamSx3('RC1_FORNEC')[1])	,"","","SA2"	,"",0,.F.})
    aAdd(aParam,{1,"Fornecedor Até"	, Space(TamSx3('RC1_FORNEC')[1])	,"","","SA2"	,"",0,.F.})

    If ParamBox(aParam,"Liberação para pagamento",@aRet,,,,,,,,.T.,.T.)

        IF ISINCALLSTACK("U_CFINA97")
            cFiltro+= "AND RTRIM(RC1_NATURE)='IRF'"
            cFiltro+= "AND RC1_INTEGR='0'
        ELSE
            cFiltro+= "AND RTRIM(RC1_NATURE)!='IRF'"
            cFiltro+= "AND RC1_INTEGR='2'
        ENDIF

        cFiltro:= "%"+cFiltro+"%"

        cTab:= GetNextAlias()
        BeginSql Alias cTab
        SELECT RC1.R_E_C_N_O_ AS RECRC1
                ,RC1.*
                ,RC0.*
                ,SA2.*
        FROM %TABLE:RC1% RC1
        INNER JOIN %TABLE:RC0% RC0 ON RC0_FILIAL=%xfilial:RC0%
            AND RC0_CODTIT=RC1_CODTIT
            AND RC0.D_E_L_E_T_=''
        INNER JOIN %TABLE:SA2% SA2 ON A2_FILIAL=%xfilial:SA2%
            AND A2_COD=RC1_FORNEC
            AND A2_LOJA=RC1_LOJA
            AND SA2.D_E_L_E_T_=''
        WHERE RC1_VENREA BETWEEN %exp:DTOS(aRet[1])% AND %exp:DTOS(aRet[2])%
            AND RC1_FILIAL BETWEEN %exp:aRet[3]% AND %exp:aRet[4]%
            AND RC1_FORNEC BETWEEN %exp:aRet[5]% AND %exp:aRet[6]%
            AND RC1.D_E_L_E_T_=''
            %Exp:cFiltro%
        ORDER BY RC1_CODTIT,RC1_VENCTO
        EndSql

        TCSETFIELD(cTab,"RC1_EMISSA","D")
        TCSETFIELD(cTab,"RC1_VENREA","D")

        //GETLastQuery()[2]
        (cTab)->(dbSelectArea((cTab)))
        (cTab)->(dbGoTop())
        WHILE (cTab)->(!EOF())
            Aadd(aTitSt,{.T.,(cTab)->RC1_CODTIT,ALLTRIM((cTab)->RC1_DESCRI),(cTab)->RC0_PREFIX,(cTab)->RC1_NUMTIT,;
                (cTab)->RC1_TIPO,(cTab)->RC1_VALOR,(cTab)->RC1_EMISSA,(cTab)->RC1_VENREA,;
                (cTab)->RC1_NATURE,(cTab)->RC1_FORNEC,(cTab)->RC1_LOJA,(cTab)->A2_NOME,;
                (cTab)->A2_EST,(cTab)->RC1_COMPET,(cTab)->RECRC1})
            (cTab)->(dbSkip())
        End
        (cTab)->(dbcloseArea())

        If Len(aTitSt)>0
            aAdvSize:= MsAdvSize()
            DEFINE MSDIALOG oDlg TITLE "Liberação para pagamento" FROM aAdvSize[7],aAdvSize[1] TO aAdvSize[6],aAdvSize[5] OF oMainWnd PIXEL STYLE DS_SYSMODAL

            EnchoiceBar(oDlg,{|| lOk:=.T. , oDlg:End() },{|| oDlg:End()},,)

            @ 08,10 SAY "Selecione os titulos para enviar para aprovação." SIZE 200,008 PIXEL OF oDlg
            @ 20,10 LISTBOX oLbx;
                FIELDS HEADER " ", RetTitle("RC1_CODTIT"),RetTitle("RC1_DESCRI"),RetTitle("RC0_PREFIX"),RetTitle("RC1_NUMTIT"),;
                RetTitle("RC1_TIPO"),RetTitle("RC1_VALOR"),RetTitle("RC1_EMISSA"),RetTitle("RC1_VENREA"),RetTitle("RC1_NATURE"),;
                RetTitle("RC1_FORNEC"),RetTitle("RC1_LOJA"),RetTitle("A2_NOME"),RetTitle("A2_EST"),RetTitle("RC1_COMPET");
                SIZE 350,085 OF oDlg PIXEL ON dblClick(aTitSt[oLbx:nAt,1]:=!aTitSt[oLbx:nAt,1])

            oLbx:SetArray( aTitSt )
            oLbx:bLine := {|| {Iif(aTitSt[oLbx:nAt,1],oOk,oNo),;
                aTitSt[oLbx:nAt,2],;
                aTitSt[oLbx:nAt,3],;
                aTitSt[oLbx:nAt,4],;
                aTitSt[oLbx:nAt,5],;
                aTitSt[oLbx:nAt,6],;
                TRANSFORM(aTitSt[oLbx:nAt,7],cPictVrl),;
                aTitSt[oLbx:nAt,8],;
                aTitSt[oLbx:nAt,9],;
                aTitSt[oLbx:nAt,10],;
                aTitSt[oLbx:nAt,11],;
                aTitSt[oLbx:nAt,12],;
                aTitSt[oLbx:nAt,13],;
                aTitSt[oLbx:nAt,14],;
                aTitSt[oLbx:nAt,15]}}
            oLbx:Align:= CONTROL_ALIGN_ALLCLIENT
            ACTIVATE MSDIALOG oDlg CENTER

            If lOk
                For nCnta:=1 to Len(aTitSt)
                    IF aTitSt[nCnta][1]
                        RC1->(DBGOTO(aTitSt[nCnta][16]))
                        IF RC1->(!EOF())

                            //Realiza integração com Fluig
                            FWMsgRun(,{|| cRet := U_CJBK03FL({aTitSt[nCnta]}) },,"Realizando integração Fluig, aguarde..." )

                            if empty(cRet)

                                RECLOCK("RC1",.F.)
                                RC1->RC1_INTEGR:= "3"
                                MSUNLOCK()

                            else

                                msgAlert("Falha ao gerar liberação: " + cRet)
                                
                            endif
                        ENDIF
                    Endif
                Next

                MSGINFO('Liberação de pagamento concluída!')
            EndIF
        Else
            MsgAlert('Não foram localizados titulos com os parametros informados!')
        EndIf
    EndIF

Return
/*/{Protheus.doc} User Function CFIN92CNABEX
    Gera CNAB Exclusivo para Clientes especificos cadastrados na Tabela ZCM - (Amarração de Contratos/Clientes)
    @type  Function
    @author Luiz Enrique
    @since 07/05/2020
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
USER FUNCTION CFIN92CNABEX()

    Local lret:= .t.
    Local oDlg
    Local oPanel1
    Local oPanel2
    Local aCoors := FWGetDialogSize(oMainWnd)//{0,0,550,1300}

    PRIVATE oBrwContrat
    PRIVATE dDTRef:= DdATABASE
    PRIVATE oDTRef
    PRIVATE cMarca      := ""	    //oBrwContrat:Mark()
    PRIVATE lInverte    := .T.      //oBrwContrat:IsInvert()
    PRIVATE LCNABEX     := .T.       //Variavel Private para ser utilizada no programa CGPER04
    //PRIVATE cCI_CNPJTJ  := Alltrim(SuperGetMv("CI_CNPJTJ",.F.,""))    //PICTURE "@R 99.999.999/9999-99"

    //---------------------------------------------------------------------------------------------------------------

    While .t.

        Define MsDialog oDlg Title 'Geração de CNABS - Clientes' From aCoors[1], aCoors[2] To aCoors[3], aCoors[4] Pixel //OF oMainWnd

        oPanel1 :=TPanel():New( 010, 010, ,oDlg, , , , , , 200, 100, .F.,.T. )
        oPanel1 :align := CONTROL_ALIGN_ALLCLIENT	//CONTROL_ALIGN_TOP

        oBrwContrat:= FWMarkBrowse():New()
        oBrwContrat:SetAlias('ZCM')
        oBrwContrat:SetDescription('CONTRATOS:')
        //oBrwContrat:SetOnlyFields( { 'ZCM_CODIGO', 'ZCM_LOCCTR', 'ZCM_RAZSOC', 'ZCM_DOCLOC','ZCM_QESCOL' } )
        oBrwContrat:SetOnlyFields( { 'ZCM_DOCLOC', 'ZCM_RAZSOC','ZCM_QESCOL' } )
        oBrwContrat:SetFieldMark('ZCM_OK')
        oBrwContrat:AllMark()
        oBrwContrat:SetAllMark({||U_BrwAllMark(oBrwContrat)})
        //oBrwContrat:SetMark("X","ZCM","ZCM_OK")
        //oBrwContrat:DisableDetails()
        //oBrwContrat:SetSemaphore(.T.)
        oBrwContrat:SetProfileID("x")
        oBrwContrat:SetOwner( oPanel1 )
        oBrwContrat:SetIgnoreARotina(.T.)
        oBrwContrat:SetMenuDef("")
        oBrwContrat:AddButton('Gerar Cnab', 'MsgRun("Aguarde...",,{|| lret:= U_CnabCliente (oBrwContrat,dDTRef)})', , 4, 0)
        oBrwContrat:AddButton('Relatório Conf.', 'U_CINF92REL()', , 4, 0)
        oBrwContrat:SetAmbiente(.F.)
        //oBrwContrat:SetFilterDefault("ZCM->ZCM_STATUS == '1'" )

        oPanel2 :=TPanel():New( 010, 010, ,oDlg, , , , , , 040, 040, .F.,.T. )
        oPanel2 :align := CONTROL_ALIGN_BOTTOM  //CONTROL_ALIGN_ALLCLIENT	//CONTROL_ALIGN_TOP
        @ 008, 003 SAY 	"Data Referência:" 						            OF oPanel2 PIXEL
        @ 007, 060 MSGET oDTRef	        VAR dDTRef  	    SIZE 50,07      OF oPanel2 PIXEL 	When .T. PICTURE "@D"
        //@ 040, 003 CHECKBOX oNivelEsc	VAR lNivelEsc PROMPT "Quebra por nível de escolaridade." 	SIZE 200,7 PIXEL OF oPanel 	//ON CLICK func()
        //@ 040, 150 BUTTON oButtonOK     PROMPT "OK"         SIZE 034,013    OF oPanel2 PIXEL Action(MsgRun("Aguarde...",,{|| lret:= CnabCliente (oBrwContrat,dDTRef)}), oDlg:End())
        //@ 040, 191 BUTTON oButtonCancel PROMPT "Cancela"    SIZE 034,013    OF oPanel2 PIXEL Action(lret:= .t., oDlg:End())

        oBrwContrat:Activate()

        ACTIVATE MSDIALOG oDlg CENTERED

        //ACTIVATE MSDIALOG oDlg CENTER ON INIT EnchoiceBar(oDlg,{||MsgRun("Aguarde...",,{|| lret:= CnabCliente (oBrwContrat,dDTRef)}),oDlg:End()},{||oDlg:End()})

        If !lret
            lret:= .T.
            Loop
        Endif

        Exit

    Enddo

Return

/*/{Protheus.doc} CnabCliente
Executa a Geração das Remessas. CNAB Modelo 2 (240)
@type  Static Function
@author Luiz Enrique
@since 11/05/2020
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
USER Function CnabCliente(oBrwContrat,dDTRef)

    Local cRoteiro := AllTrim(SuperGetMV("CI_ROTECH",,"FOL"))
    Local cDCnbCli := AllTrim(SuperGetMV("CI_CNABCL",,"\ARQ_TXT\KAIROS\SPBA\CLIENTES\")) //Diretório do CNAB de clientes
    Local lInverte := .F.
    Local cMarca   := ""
    Local aBancos  := {}
    Local nPos     := 0
    Local cTab     := ""
    Local cProcFol := ""
    Local lCont    := .F.

    IF Empty(dDTRef)
        Alert("Data de pagamento é obrigatória.")
        RETURN .f.
    Endif

    DEFINE MSDIALOG oDlg TITLE "CNAB Cliente" From 000,000 to 085,280 COLORS 0, 16777215 PIXEL

	@ 006, 009 SAY oSay PROMPT "Data de Pagamento:" SIZE 073,007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 005,084 MSGET oGet VAR dDTRef SIZE 045,011 OF oDlg COLORS 0, 16777215 PIXEL
	@ 022,093 BUTTON oButtonOK PROMPT "OK" SIZE 034,013 OF oDlg PIXEL Action(lRet:= .T., oDlg:End())
	@ 022,054 BUTTON oButtonCancel PROMPT "Cancela" SIZE 034,013 OF oDlg PIXEL Action(lRet:= .F., oDlg:End())

	ACTIVATE MSDIALOG oDlg CENTERED
	
	If !lRet
		Return
	EndIf
 
    cMarca  := oBrwContrat:Mark()
    lInverte:= oBrwContrat:IsInvert()

    ZCM->(DBGOTOP( ))
    While ZCM->(!EOF()) .and. ZCM->ZCM_FILIAL == Xfilial("ZCM")

        IF ((ZCM->ZCM_OK  <> cMarca .And. lInverte) .Or. (ZCM->ZCM_OK  == cMarca .And. !lInverte ))

            cProcFol:= ""
            aBancos := {}

            cTab:= GetNextAlias()
            BeginSql Alias cTab
            SELECT DISTINCT RD_PROCES
                ,LEFT(RA_BCDEPSA,3) AS BANCO
                ,SUBSTRING(RCC.RCC_CONTEU,24,5) AS AGENCIA
                ,SUBSTRING(RCC.RCC_CONTEU,30,12) AS CONTA
                ,SUBSTRING(RCC.RCC_CONTEU,50,12) AS ARQCFG
            FROM %TABLE:SRD% SRD
            INNER JOIN %TABLE:SRA% SRA ON RA_FILIAL=RD_FILIAL
                AND RA_MAT=RD_MAT
                AND SRA.D_E_L_E_T_=' '
            INNER JOIN %TABLE:RCC% RCC ON
                RCC.RCC_FILIAL = %xfilial:RCC%
                AND RCC.RCC_CODIGO='S052'
                AND SUBSTRING(RCC.RCC_CONTEU,21,3)= LEFT(RA_BCDEPSA,3)
                AND RCC.D_E_L_E_T_ = ' '
            WHERE RD_FILIAL=%xfilial:SRD%
                AND RD_DATPGT=%exp:dDTRef%
                AND RD_XIDCNT=%exp:ZCM->ZCM_CODIGO%
                AND RA_XIDLOCT IN (SELECT ZR8_LOCCTR FROM  %TABLE:ZR8%  ZR8 WHERE ZR8_CODIGO = %exp:ZCM->ZCM_CODIGO% AND ZR8.D_E_L_E_T_='')
                //AND RD_XIDLOC=%exp:ZCM->ZCM_LOCCTR%
                AND SRD.D_E_L_E_T_=''
            ORDER BY RD_PROCES
            EndSql

            //GETLastQuery()[2]
            While (cTab)->(!EOF())

                IF !((cTab)->RD_PROCES$cProcFol)
                    cProcFol += (cTab)->RD_PROCES
                ENDIF

                IF ASCAN(aBancos,{|x| x[1]==(cTab)->BANCO })==0
                    AADD(aBancos,{(cTab)->BANCO,(cTab)->AGENCIA,(cTab)->CONTA,(cTab)->ARQCFG})
                Endif


                (cTab)->(dbSkip())
            End
            (cTab)->(dbcloseArea())

            If !Empty(cProcFol)

                For nPos:= 1 to len(aBancos)
                	
                	lCont := .T.
                	
                    Pergunte("XGPEM080R1", .F.)

                    MV_PAR01   := cRoteiro     					            //  Roteiros
                    // MV_PAR02        										//  Roteiros
                    // MV_PAR03        										//  Roteiros
                    MV_PAR04   := "        "   								//  Filial  De
                    MV_PAR05   := "ZZZZZZZZ"   								//  Filial  Ate
                    MV_PAR06   := "         "     							//  Centro de Custo De
                    MV_PAR07   := "ZZZZZZZZZ"     							//  Centro de Custo Ate
                    MV_PAR08   := "        "  								//  Banco /Agencia De
                    MV_PAR09   := "ZZZZZZZZ"  								//  Banco /Agencia Ate
                    MV_PAR10   := "      "   								//  Matricula De
                    MV_PAR11   := "ZZZZZZ"     								//  Matricula Ate
                    MV_PAR12   := "                              "     		//  Nome De
                    MV_PAR13   := "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"     		//  Nome Ate
                    MV_PAR14   := "            "  							//  Conta Corrente De
                    MV_PAR15   := "ZZZZZZZZZZZZ"  							//  Conta Corrente Ate
                    MV_PAR16   := " ADFT"        							//  Situacao
                    MV_PAR17   := 2     									//  Layout  cnab modelo 2
                    MV_PAR18   := aBancos[nPos,4]             		        //  Arquivo de configuracao
                    MV_PAR19   := cDCnbCli + ALLTRIM(ZCM->ZCM_ARQUIV)       //  nome do arquivo de saida
                    MV_PAR20   := dDTRef									//  data de credito
                    MV_PAR21   := dDTRef		  							//  Data de Pagamento De
                    MV_PAR22   := dDTRef									//  Data de Pagamento Ate
                    MV_PAR23   := "ACDEGHIJMPST***"    						//  Categorias
                    MV_PAR24   := 3     									//  Imprimir 1-Funcionarios 2-Beneficiarias 3-Ambos
                    MV_PAR25   := dDTRef									//  Data de Referencia
                    MV_PAR26   := cProcFol     						        //  Selecao de Processos
                    MV_PAR27   := ""       									//  Selecao de Processos
                    MV_PAR28   := " "     									//  Numero do Pedido     -- SUBSTITUIDO PELO NUMERO DO PEDIDO
                    MV_PAR29   := 2     									//  Linha Vazia no Fim do Arquivo 1=Sim 2=Nao
                    MV_PAR30   := AvKey(aBancos[nPos,1],"EE_CODIGO")        //  Processar Banco*/
                    MV_PAR31   := AvKey(aBancos[nPos,2],"EE_AGENCIA")       //  Agencia*/
                    MV_PAR32   := AvKey(aBancos[nPos,3],"EE_CONTA")         //  Conta*/
                    MV_PAR33   := 3   										//  Gerar Conta Tipo   1=Conta corrente 2=Conta Poupanca 3=Ambas
                    MV_PAR34   := 2			    							//  DOC Outros Bancos  1=Sim 2=Não
                    MV_PAR35   := 1											//  Validar Cta Bancarias R$ 0.01?  1=Nao  2=Sim
                    MV_PAR36   := ctod("")									//  Data de admissao de
                    MV_PAR37   := ctod("")									//  Data de admissao Fim
                    MV_PAR38   := 2          								//  Cnab Exclusivo para cliente especifico ? 1= Não, 2=Sim

                    U_CGPER04(.T.)

                Next

            endIf

        ENDIF

        ZCM->(DbSkip())
    ENDDO
    
    If lCont
    	MSGINFO("Processamento concluído!")
    Else
    	MSGINFO("Não existem dados para essa data de referência!")
    EndIf

Return .t.
//-----------------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} BrwAllMark
Controle das Seleções na lista de Contratos - MARCAS/DESMARCA TODOS
@author Luiz Enrique de Araujo
@since 03/06/2020
@version 1.0
/*/
//------------------------------------------------------------------------------------------------------------------------------
USER Function BrwAllMark(oObj)

    Local nreg:= ZCM->(Recno())

    lMarkAll := !lMarkAll
    cMarca   := oObj:Mark()

    ZCM->(DBGOTOP( ))

    While ZCM->(!EOF()) .and. ZCM->ZCM_FILIAL == Xfilial("ZCM")
        ZCM->(Reclock("ZCM",.F.))
        ZCM->ZCM_OK := Iif(lMarkAll,cMarca," ")
        ZCM->(MsUnlock())
        ZCM->(DbSkip())
    EndDo

    ZCM->(DbGoto(nreg))

    oObj:Refresh()

Return Nil

/*/{Protheus.doc} C06A92RS
Relatório sintético bolsa auxilio
@author Carlos Henrique
@since 27/04/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function C06A92RS()

    FWMsgRun(,{|| U_CJBK03RS() },,"Imprimindo relatório sintético de bolsa auxílio, aguarde..." )

return

/*/{Protheus.doc} CINF92REL
Relatório conferência CNAB Clientes
@author André Brito
@since 18/08/2020
@version 1.0
/*/
User Function CINF92REL()

    Local aPWiz   := {}
    Local aRetWiz := {}
    Local lRet    := .T.
    Local dDtPgto := CTOD("")

    aAdd(aPWiz,{ 1,"Data de pagamento: "               ,Ctod("") ,"","",""   ,  ,60 ,.T.})
    aAdd(aRetWiz,Ctod(""))

    lRet := ParamBox(aPWiz,"Conferencia CNAB Clientes",aRetWiz,,,,,,,,.T.,.T.)

    dDtPgto   := aRetWiz[1]

    If lRet
        FWMsgRun(,{|| U_CFIN92IMP(dDtPgto) },,"Imprimindo relatório amarração contratos, aguarde..." )
    EndIf

Return

/*/{Protheus.doc} CFIN92IMP
Impressão do relatório conferência CNAB Clientes
@author André Brito
@version undefined
@type function
/*/

User Function CFIN92IMP(dDtPgto)

    Local lRet      := .T.
    Local cTmpPath 	:= GetTempPath()
    Local nTotMov	:= 0
    Local cTotGer	:= 0
    Local cNomeRel  := "CNAB Clientes"
    Local cNumTit   := ""
    Local nOutros	:= 0
    Local nTotGer	:= 0
    Local cDescr    := ""
    Local dDtaPag   := CTOD("//")
    Local cTab		:= GetNextAlias()
    Local dDtPgt    := DTOS(dDtPgto)
    Local dVenc
    Local dDataDe
    Local dDataAte

    Private nLin	:= 0
    Private nAtuPag	:= 1
    Private nTotPag	:= 0
    Private cLogo	:= GetSrvProfString("Startpath","")+"\LGMID"+CEMPANT+".PNG"
    Private oFnt9 	:= TFont():New('Arial',,-9,,.F.)
    Private oFntb9 	:= TFont():New('Arial',,-9,,.T.)
    Private oFntb14 := TFont():New('Arial',,-14,,.T.)
    Private oPrint	:= NIL
    Private cPictVrl:= PESQPICT("RC1","RC1_VALOR")

    BeginSql Alias cTab
%NOPARSER%
	SELECT DISTINCT LEFT(ZC7_COMPET,2) +'/'+ RIGHT(ZC7_COMPET,4) AS COMPETENCIA
		,RTRIM(RD_XIDCNT)+'*'+ RTRIM(RD_XIDLOC)+'*'+ RD_XIDFOL AS CONVENIO
		,ZC1_RAZSOC AS DESCCONV
		,(SELECT COUNT(RD_MAT) FROM %table:SRD% SRDA
			INNER JOIN %table:SRA% SRA ON RA_MAT=RD_MAT
				AND SRA.D_E_L_E_T_=''
			WHERE SRDA.RD_XIDFOL=SRD.RD_XIDFOL
				AND RD_PD='J99'
				AND SRDA.D_E_L_E_T_='' ) AS QTDEBOLSA
		,(SELECT SUM(RD_VALOR) FROM %table:SRD% SRDA
			INNER JOIN %table:SRA% SRA ON RA_MAT=RD_MAT
				AND SRA.D_E_L_E_T_=''
			WHERE SRDA.RD_XIDFOL=SRD.RD_XIDFOL
				AND RD_PD='004'
				AND SRDA.D_E_L_E_T_='' ) AS TOTALBOLSA
		,(SELECT ISNULL(SUM(RD_VALOR),0) FROM %table:SRD% SRDA
			INNER JOIN %table:SRA% SRA ON RA_MAT=RD_MAT
				AND SRA.D_E_L_E_T_=''
			WHERE SRDA.RD_XIDFOL=SRD.RD_XIDFOL
				AND RD_PD='277'
				AND SRDA.D_E_L_E_T_='' ) AS TOTALAUXTRANSP
		,(SELECT ISNULL(SUM(RD_VALOR),0) FROM %table:SRD% SRDA
			INNER JOIN %table:SRA% SRA ON RA_MAT=RD_MAT
				AND SRA.D_E_L_E_T_=''
			WHERE SRDA.RD_XIDFOL=SRD.RD_XIDFOL
				AND RD_PD='509'
				AND SRDA.D_E_L_E_T_='' ) AS VALORIRRF
		,(SELECT ISNULL( SUM(RD_VALOR),0 ) FROM %table:SRD% SRDA
			WHERE SRDA.RD_XIDFOL=SRD.RD_XIDFOL
				AND RD_PD IN ('530',"554")
				AND SRDA.D_E_L_E_T_='' ) AS VALORPENSAO
		,(SELECT ISNULL( SUM(RD_VALOR),0 ) FROM %table:SRD% SRDA
			WHERE SRDA.RD_XIDFOL=SRD.RD_XIDFOL
				AND RD_PD='J99'
				AND SRDA.D_E_L_E_T_='' ) AS LIQUIDOAPAGAR
	FROM %table:SRD% SRD
		INNER JOIN %table:ZC1% ZC1 ON ZC1_LOCCTR=RD_XIDLOC
			AND ZC1.D_E_L_E_T_=''
		INNER JOIN %table:ZC7% ZC7 ON ZC7_IDFOL=RD_XIDFOL
			AND ZC7.D_E_L_E_T_=''
	WHERE SRD.D_E_L_E_T_=''
		//AND RD_XIDLOC =%Exp:ZCM->ZCM_LOCCTR%
		AND RD_XIDCNT =%Exp:ZCM->ZCM_CODIGO%
        AND RA_XIDLOC IN (SELECT ZR8_LOCCTR FROM  %TABLE:ZR8%  ZR8 WHERE ZR8_CODIGO = %exp:ZCM->ZCM_CODIGO% AND ZR8.D_E_L_E_T_='')
		AND RD_DATPGT =%Exp:dDtPgt%
    EndSql

    (cTab)->(dbSelectArea((cTab)))

    Count To nTotMov

    (cTab)->(dbGoTop())

    If (cTab)->(!EOF())

        nTotPag := nTotMov / 73

        If INT(nTotPag) < nTotPag
            nTotPag := INT(nTotPag) + 1
        Endif

        FERASE("\spool\"+cNomeRel+".pdf")
        FERASE("\spool\"+cNomeRel+".rel")

        oPrint:= FWMSPrinter():New(cNomeRel+".rel",IMP_PDF,.F.,"\spool\",.T.,.F.,,,.T.,.T.,,.T.)
        oPrint:SetLandscape(.T.)
        oPrint:SetResolution(78)
        oPrint:SetPaperSize(DMPAPER_A4)
        oPrint:SetMargin(40,40,40,40)
        oPrint:nDevice  := IMP_PDF
        oPrint:cPathPDF := "\spool\"
        oPrint:lServer  := .T.
        oPrint:lViewPDF := .F.
        oPrint:StartPage()

        CFIN92LR(cNumTit,cDescr,dDtPgt)

        WHILE (cTab)->(!EOF())

            If (nLin > 590)
                oPrint:EndPage()
                oPrint:StartPage()
                nAtuPag+= 1
                CFIN92LR(cNumTit,cDescr,dDtaPag)

            EndIf

            oPrint:Say(nLin,11,(cTab)->COMPETENCIA,oFnt9)
            oPrint:Say(nLin,61,(cTab)->CONVENIO,oFnt9)
            oPrint:Say(nLin,201,(cTab)->DESCCONV,oFnt9)
            oPrint:SayAlign(nLin-10,441,CVALTOCHAR((cTab)->QTDEBOLSA),oFnt9,46,,,1,0)
            oPrint:SayAlign(nLin-10,491,TRIM(TRANSFORM((cTab)->TOTALBOLSA,cPictVrl)),oFnt9,58,,,1,0)
            oPrint:SayAlign(nLin-10,553,TRIM(TRANSFORM((cTab)->TOTALAUXTRANSP,cPictVrl)),oFnt9,58,,,1,0)
            oPrint:SayAlign(nLin-10,615,TRIM(TRANSFORM((cTab)->VALORIRRF,cPictVrl)),oFnt9,58,,,1,0)
            oPrint:SayAlign(nLin-10,677,TRIM(TRANSFORM((cTab)->VALORPENSAO,cPictVrl)),oFnt9,58,,,1,0)
            //  oPrint:SayAlign(nLin-10,739,TRIM(TRANSFORM(nOutros,cPictVrl)),oFnt9,58,,,1,0)
            oPrint:SayAlign(nLin-10,801,TRIM(TRANSFORM((cTab)->LIQUIDOAPAGAR,cPictVrl)),oFnt9,68,,,1,0)

            nTotGer += (cTab)->LIQUIDOAPAGAR
            nLin += 10

            (cTab)->(dbSkip())

            If (cTab)->(Eof())
                nLin := 590
                oPrint:Box(590,736,600,870)
                oPrint:Line(nLin,798,600,798)
                oPrint:Say(nLin+8,739,"TOTAL (R$)",oFnt9)
                oPrint:SayAlign(nLin-1,801,TRIM(TRANSFORM(nTotGer,cPictVrl)),oFnt9,68,,,1,0)
                oPrint:SayAlign(nLin-1,11,"Gerado automaticamente pelo Sistema - Protheus",oFnt9,348,,,0,0)
            EndIf
        EndDo

        oPrint:EndPage()

        oPrint:Print()

        FreeObj(oPrint)
    Else

        MsgInfo("Não há dados a serem exibidos", "Aviso")

        Return

    EndIf
    (cTab)->(dbCloseArea())

    cNomeRel := cNomeRel+".pdf"
    cDirRel	 := "\spool\"+cNomeRel
    lRet	 := FILE(cDirRel) //VerIfica se gerou o PDF

    If lRet

        CpyS2T( cDirRel, cTmpPath, .F. )

        If File(cTmpPath+cNomeRel)
            ShellExecute("OPEN",cTmpPath+cNomeRel,"","",5)
        Else
            MsgAlert("Não foi possível realizar a cópia do relatório para o diretório:" + CRLF + cTmpPath)
        EndIf

    EndIf

Return lRet

/*/{Protheus.doc} CFIN92LR
Rotina de impressão do layout do relatório
@author André Brito
@since 10/07/2020
@version 12.1.25
@type function
/*/

Static function CFIN92LR(cNumTit,cDescr,dDtPgt)

    oPrint:Box(10,10,590,870)

    oPrint:SayBitmap(01,20,cLogo,080,090)
    oPrint:Line(10,10,10,870)
    oPrint:Line(10,120,85,120)
    oPrint:Line(30,120,30,870)
    oPrint:Line(30,220,85,220)

    oPrint:SAY(24,380,"RELATÓRIO CONFERÊNCIA CNAB CLIENTE",oFntb14)
    
    dDtPgt := STOD(dDtPgt)
    
    oPrint:SAY(40,122,"Número:",oFntb9)
    oPrint:Say(40,222,cNumTit,oFnt9)
    oPrint:Line(42,120,42,870)
    oPrint:SAY(50,122,"Descritivo:",oFntb9)
    oPrint:Say(50,222,cDescr,oFnt9)
    oPrint:Line(52,120,52,870)
    oPrint:SAY(60,122,"Data de Pagamento:",oFntb9)
    oPrint:Say(60,222,DTOC(dDtPgt),oFnt9)
    oPrint:Line(62,120,62,870)
    oPrint:SAY(70,122,"Data da Integração:",oFntb9)
    oPrint:Say(70,222,DTOC(DATE()),oFnt9)
    oPrint:Line(72,120,72,870)
    oPrint:SAY(80,122,"Página:",oFntb9)
    oPrint:Say(80,222,CVALTOCHAR(nAtuPag) +  " de " + CVALTOCHAR(nTotPag) ,oFnt9)

    nLin := 85
    oPrint:Line(nLin,10,nLin,870)
    oPrint:Line(nLin,60,590,60)
    oPrint:Line(nLin,200,590,200)
    oPrint:Line(nLin,440,590,440)
    oPrint:Line(nLin,488,590,488)
    oPrint:Line(nLin,550,590,550)
    oPrint:Line(nLin,612,590,612)
    oPrint:Line(nLin,674,590,674)
    oPrint:Line(nLin,736,590,736)
    oPrint:Line(nLin,798,590,798)
    oPrint:SAY(nLin+9,11,"Competência",oFntb9)
    oPrint:SAY(nLin+9,61,"Contrato\Local\Folha",oFntb9)
    oPrint:SAY(nLin+9,201,"Descrição", oFntb9)
    oPrint:SAY(nLin+9,441,"Qtde. Bolsas",oFntb9)
    oPrint:SAY(nLin+9,491,"Total Bolsa", oFntb9)	//	"Total de Bolsas", oFntb9)
    oPrint:SAY(nLin+9,553,"Total Transp.", oFntb9)	//	"Tot.Aux.Transp.", oFntb9)
    oPrint:SAY(nLin+9,615,"Valor IR", oFntb9)	//	"IR e Pensão", oFntb9)
    oPrint:SAY(nLin+9,677,"Valor Pensão", oFntb9)	//	"CI Devida", oFntb9)
    oPrint:SAY(nLin+9,739,"Outros", oFntb9)	//	"CI Recebida", oFntb9)
    oPrint:SAY(nLin+9,801,"Líquido a Pagar", oFntb9)	//	"Total da Folha", oFntb9)
    oPrint:Line(nLin+12,10,nLin+12,870)

    nLin += 22

Return
