#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE "FWMVCDEF.CH"


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CFATA01
Interface de monitoramento de Notas
@author  	Carlos Henrique
@since     	19/02/2018
@version  	P.12      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CFATA01()
Local oBrowse := FwMBrowse():New()

oBrowse:SetAlias("ZC5")
oBrowse:SetDescription("Monitoramento de Notas") 


//Legendas para o browse
oBrowse:Addlegend("ZC5_STATUS=='0'" , "BR_CINZA"	, "Aguardando Faturamento")
oBrowse:Addlegend("ZC5_STATUS=='1'" , "BR_AMARELO"	, "Faturamento em andamento")
oBrowse:Addlegend("ZC5_STATUS=='2'" , "BR_AZUL"		, "Faturamento Realizado\Aguardando Transmissão Prefeitura")
oBrowse:Addlegend("ZC5_STATUS=='3'" , "BR_VERMELHO"	, "Falha no Processamento")
oBrowse:Addlegend("ZC5_STATUS=='4'" , "BR_VERDE"	, "Faturamento Realizado\Transmissão Prefeitura Realizada")
oBrowse:Addlegend("ZC5_STATUS=='4' .AND. ZC5_SERIE=='DIV'" , "BR_VERDE_ESCURO"	, "Faturamento realizado sem nf")
oBrowse:Addlegend("ZC5_STATUS=='5'" , "BR_LARANJA"	, "Aguardando Cancelamento de nota")
oBrowse:Addlegend("ZC5_STATUS=='6'" , "BR_MARRON"	, "Cancelamento em andamento")
oBrowse:Addlegend("ZC5_STATUS=='7'" , "BR_AZUL_CLARO"	, "Falha no Cancelamento")
oBrowse:Addlegend("ZC5_STATUS=='8'" , "BR_CANCEL"	, "Nota cancelada")
oBrowse:Addlegend("ZC5_STATUS=='T'" , "BR_PINK"		, "Fila  de processamento travada para ajuste")
oBrowse:Addlegend("ZC5_STATUS=='O'" , "BR_BRANCO"	, "Aguardando aprovação - Serviços Diversos")
oBrowse:Addlegend("ZC5_STATUS=='P'" , "BR_MARROM"	, "Aguardando Faturamento - serviços diversos")
oBrowse:Addlegend("ZC5_STATUS=='E'" , "BR_CANCEL"	, "Cancelado")
oBrowse:Addlegend("ZC5_STATUS=='R'" , "BR_VIOLETA"	, "Reprovado")

// Ativação da Classe
oBrowse:Activate()

Return
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina de definição do menu
@author  	Carlos Henrique
@since     	19/02/2018
@version  	P.12      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE "Pesquisar" ACTION "AxPesqui" OPERATION 1	ACCESS 0 		
ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.CFATA01" OPERATION 2 ACCESS 0 	
ADD OPTION aRotina TITLE "Excluir serv. diversos" ACTION "u_C05A01EX" OPERATION 6	ACCESS 0	
ADD OPTION aRotina TITLE "Faturamento Manual" ACTION "U_C05A01FM" OPERATION 6	ACCESS 0
ADD OPTION aRotina TITLE "Cancelamento Manual NFS-E" ACTION "U_C05A01CM" OPERATION 6	ACCESS 0
ADD OPTION aRotina TITLE "Gerar retorno SOE" ACTION "U_C05A01GR()" OPERATION 6	ACCESS 0
//ADD OPTION aRotina TITLE "Gerar retorno SOE em lote" ACTION "U_C05A01GL()" OPERATION 6	ACCESS 0
ADD OPTION aRotina TITLE "Manutenção do E-mail do Cliente" ACTION "U_C05A01ME()" OPERATION 6	ACCESS 0
ADD OPTION aRotina TITLE "Cons. Aprov." ACTION "U_CCFGE15" OPERATION 6	ACCESS 0
ADD OPTION aRotina TITLE "Conhecimento" ACTION "U_C05A01CO()" OPERATION 6 ACCESS 0 
ADD OPTION aRotina TITLE "Imprimir" ACTION "U_CFATR03" OPERATION 6	ACCESS 0  	

Return(aRotina)
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina de definição do MODEL
@author  	Carlos Henrique
@since     	19/02/2018
@version  	P.12      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function ModelDef()
Local oStruZC5 	:= FWFormStruct(1, "ZC5")  
Local oModel   	:= MPFormModel():New( "CFATA01MD", /*bPreValidacao*/, {|oMdl| MDMVlPos( oMdl ) }/*bPosVld*/, /*bCommit*/, /*bCancel*/ )

oModel:AddFields("ZC5MASTER", /*cOwner*/, oStruZC5)
oModel:SetPrimaryKey({"ZC5_FILIAL","ZC5_RPSSOC"})
oModel:SetDescription("Monitoramento de Notas")

Return oModel
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina de definição do VIEW
@author  	Carlos Henrique
@since     	19/02/2018
@version  	P.12      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function ViewDef()
Local oView    	:= FWFormView():New()
Local oStruZC5 	:= FWFormStruct(2,"ZC5")  
Local oModel   	:= FWLoadModel("CFATA01")           	


oView:SetModel(oModel)
oView:AddField('VIEW_ZC5', oStruZC5, "ZC5MASTER")
oView:CreateHorizontalBox("GERAL", 100)
oView:SetOwnerView('VIEW_ZC5', "GERAL")

Return oView

user Function C05A01EX()    
	Local oDlg
	Local cMotivo           := ""
	Local oSay
	local oMsg
	local oBtOk
	local oBtCancel
	local lMotivo			:= .f.

	If ( ZC5->ZC5_STATUS != "P" )
		if ( ZC5->ZC5_STATUS == "O" )
			Help( ,, "HELP","MDMVlPos", "Pedido em aprovação não pode ser excluido.", 1, 0)  
		else
			Help( ,, "HELP","MDMVlPos", "Não é permitida exclusão, somente para serviços diversos.", 1, 0)  
		endif
          
	else

		DEFINE MSDIALOG oDlg TITLE "Motivo" FROM 0, 0  TO 200, 300 PIXEL
			oSay:= TSay():Create(oDlg,{||'Motivo da exclusão: '},05,10,,,,,,.T.,;
				CLR_RED,CLR_WHITE,200,20)
			@ 13, 15 GET oMsg VAR cMotivo MEMO SIZE 120,70 PIXEL VALID fValidExc(@cMotivo, @lMotivo)
			oBtOk        := TButton():New(85, 25,  "Confirma", oDlg,;
	    				{ || lMotivo := .t., oDlg:End()},37,12,,,.F.,.T.,.F.,,.F.,,,.F. )
			
			oBtCancel       := TButton():New(85, 75,  "Cancela", oDlg,;
	    				{ || lMotivo := .f., oDlg:End()},37,12,,,.F.,.T.,.F.,,.F.,,,.F. )
		ACTIVATE MSDIALOG oDlg CENTER

		if lMotivo

			reclock("ZC5", .F.)
			
			ZC5->ZC5_STATUS := "E"
			ZC5->ZC5_MSGLOG := cMotivo
			ZC5->ZC5_DTCANC := date()

			ZC5->(msunlock())

			dbselectArea("ZAA")

			ZAA->(dbSetOrder(3))

			if ZAA->(msseek(xfilial("ZAA") + ALLTRIM(UsrRetName(RetCodUsr()))))

				DbselectArea("ZAJ")
			
				RecLock("ZAJ", .T.)
				
					ZAJ->ZAJ_FILIAL := xFilial("ZAJ")
					ZAJ->ZAJ_NUM    := AllTrim(ZC5->ZC5_NUMSOC)
					ZAJ->ZAJ_REGRA  := "SERDIV"
					ZAJ->ZAJ_MATRES := AllTrim(ZAA->ZAA_MAT)
					ZAJ->ZAJ_DATLIB := dDatabase
					ZAJ->ZAJ_HORLIB := SUBSTR(TIME(), 1, 5)
					ZAJ->ZAJ_OBS    := cMotivo
					ZAJ->ZAJ_STATUS := "4"
					ZAJ->ZAJ_NOMRES  := ALLTRIM(UsrRetName(RetCodUsr()))
				
				ZAJ->(MsUnLock())									
			
				ZAJ->(DbCloseArea())
			
			endif

			U_C05A01EN(@cMotivo)

		endif

	EndIf
Return

Static Function fValidExc(cMotivo, lMotivo)

	Local lRet := .T.

	if lMotivo
		If Empty(cMotivo)
		
			lRet := .F.
		
		EndIf
	endif

Return lRet

user function C05A01EN(cMotivo)
	Local cUser    := GetMv("MV_RELACNT")
	Local cPass    := GetMv("MV_RELPSW")
	Local cSendSrv := GetMv("MV_RELSERV")
	Local cMsg := ""
	Local nSendPort := 0, nSendSec := 60, nTimeout := 0
	Local xRet
	Local oServer, oMessage
	Local lRet := .T.
	local cSolicit
	local cSuper
	local cNomeSol

	Default cCopia := ""
	Default cAprov := ""
   
	nTimeout := 60 
   
	oServer := TMailManager():New()
   
	if nSendSec == 0
		nSendPort := 25
	elseif nSendSec == 1
		nSendPort := 465
		oServer:SetUseSSL( GetMV("MV_RELSSL") )
	else
		nSendPort := 587 
		oServer:SetUseTLS( GetMV("MV_RELTLS") )
	endif

	xRet := oServer:Init( "", cSendSrv, cUser, cPass, , nSendPort )
	if xRet != 0
		cMsg := "Nao foi possivel se conectar ao servidor: " + oServer:GetErrorString( xRet )
		cMsg += "" + CRLF + "Contate o administrador do sistema."
		u_uCONOUT( cMsg )
		lRet := .F.
		return lRet
	endif

	xRet := oServer:SetSMTPTimeout( nTimeout )
	if xRet != 0
		cMsg := "Could not set " + cProtocol + " timeout to " + cValToChar( nTimeout )
		cMsg += "" + CRLF + "Contate o administrador do sistema."
		u_uCONOUT( cMsg )
	endif

	xRet := oServer:SMTPConnect()
	if xRet <> 0
		cMsg := "Erro ao conectar ao servidor SMTP: " + oServer:GetErrorString( xRet )
		cMsg += "" + CRLF + "Contate o administrador do sistema."
		u_uCONOUT( cMsg )
		lRet := .F.
		return lRet
	endif

	xRet := oServer:SmtpAuth( cUser, cPass )
	if xRet <> 0
		cMsg := "Nao foi possivel se autenticar no servidor SMTP: " + oServer:GetErrorString( xRet )
		cMsg += "" + CRLF + "Contate o administrador do sistema."
		u_uCONOUT( cMsg )
		oServer:SMTPDisconnect()
		lRet := .F.
		return lRet
	endif
   
	oMessage := TMailMessage():New()
	oMessage:Clear()

	dbSelectArea("ZAA")
	ZAA->(dbSetOrder(1))

	ZAA->(msSeek(xFilial("ZAA") + alltrim(ZC5->ZC5_SOLIC)))

	cSolicit := ZAA->ZAA_EMAIL
	cNomeSol := alltrim(ZAA->ZAA_NOME)

	dbSelectArea("ZAJ")
	ZAJ->(dbSetOrder(1))

	ZAJ->(msSeek(xFilial("ZAJ") + PADR(alltrim(ZC5->ZC5_NUMSOC), tamsx3("ZAJ_NUM")[1]) + "SERDIV"))

	ZAA->(msSeek(xFilial("ZAA") + alltrim(ZAJ->ZAJ_MATRES)))

	cSuper := ZAA->ZAA_EMAIL
   
	oMessage:cDate    := cValToChar( Date() )
	oMessage:cFrom    := cUser
	oMessage:cTo      := alltrim(cSolicit)     //Alltrim(GetMv("CI_MAILCOM"))
	oMessage:cCc	  := alltrim(cSuper)
	oMessage:cSubject := "Cancelamento de serviço diverso"  //"CIEE - Solicitacao de compras"
	oMessage:cBody    := FBODY(@cMotivo, cNomeSol)
	
	xRet := oMessage:Send( oServer )

	if xRet <> 0
		cMsg := "Nao foi possivel enviar a mensagem: " + oServer:GetErrorString( xRet )
		cMsg += "" + CRLF + "Contate o administrador do sistema."
		u_uCONOUT( cMsg )
	else
		u_uCONOUT("Email enviado para compras com sucesso!")
	endif
   
	xRet := oServer:SMTPDisconnect()
	if xRet <> 0
		cMsg := "Falha ao desconectar de servidor SMTP: " + oServer:GetErrorString( xRet )
		cMsg += "" + CRLF + "Contate o administrador do sistema."
		u_uCONOUT( cMsg )
	endif
return lRet

Static Function FBODY(cMotivo, cNome)
	Local cBody     := ""
			
	cBody += '<html>'
	cBody += ''
	cBody += '<head>'
	cBody += '<meta http-equiv="Content-Language" content="pt-br">'
	cBody += '<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">'
	cBody += '<meta name="GENERATOR" content="Microsoft FrontPage 3.0">'
	cBody += '<meta name="ProgId" content="FrontPage.Editor.Document">'
	cBody += '<title>CANCELAMENTO DE PRE-NOTA</title>'
	cBody += '<style>'
	cBody += ''
	cBody += 'TD {'
	cBody += 'FONT-FAMILY: Verdana, Arial, Helvetica, sans-serif; FONT-SIZE: 10pt'
	cBody += '}'
	cBody += ''
	cBody += '.TableRowWhiteMini2 {'
	cBody += 'COLOR: #000000; FONT-FAMILY: Verdana, Arial, Helvetica, sans-serif; FONT-SIZE: 10px; VERTICAL-ALIGN: middle'
	cBody += '}'
	cBody += '.TableRowBlueDarkMini {'
	cBody += 'BACKGROUND-COLOR: #717C92; COLOR: #ffffff; FONT-FAMILY: Verdana, Arial, Helvetica, sans-serif; FONT-SIZE: 10px; VERTICAL-ALIGN: middle'
	cBody += '}'
	cBody += ''
	cBody += '}'
	cBody += '.TableRowYellow {'
	cBody += 'BACKGROUND-COLOR: #B4BAC6; COLOR: #074b85; FONT-FAMILY: Verdana, Arial, Helvetica, sans-serif; FONT-SIZE: 12px; VERTICAL-ALIGN: top'
	cBody += '}'
	cBody += ''
	cBody += '.TableColumnTitle {'
	cBody += 'BACKGROUND-COLOR: #B4BAC6; COLOR: #074b85; FONT-FAMILY: Verdana, Arial, Helvetica, sans-serif; FONT-SIZE: 14px; FONT-WEIGHT: bold; VERTICAL-ALIGN: top'
	cBody += '}'
	cBody += ''
	cBody += '.style4 {'
	cBody += 'font-family: Verdana, Arial, Helvetica, sans-serif;'
	cBody += 'font-size: 12px;'
	cBody += '}'
	cBody += '	'
	cBody += '.style41 { color: #444444; font-size: 10px}'
	cBody += ''
	cBody += '.style5 {'
	cBody += 'font-family: Verdana, Arial, Helvetica, sans-serif;'
	cBody += 'font-size: 12px;'
	cBody += 'color: red;'
	cBody += '}'
	cBody += '</style>'
	cBody += '</head>'
	cBody += ''
	cBody += '<body>'
	cBody += '<form action="mailto:%WFMailTo%" method="POST" name="FrontPage_Form1">'
	cBody += '<table width=100% height=100% border=0 cellpadding=0 cellspacing=0>'
	cBody += '<tr>'
	cBody += '<td valign=top>'
	cBody += '<table width=745 border=0 align=center cellpadding=0 cellspacing=0>'
	cBody += '<tr>'
	cBody += '<td width=800>'
	cBody += '<tr>'
	cBody += '<td width=800><div align=center id="topoimg" ><img id="imgtopo" src="http://ciee.fluig.com:8210/portal/api/servlet/image/1/custom/logo_image.png" width=183 height=80></div></td>'
	cBody += '</tr>'
	cBody += '</td>'
	cBody += '</tr>'
	cBody += '<tr bgcolor=#ffffff>'
	cBody += '<td>'
	cBody += '<p><br>'
	cBody += '<br>'
	cBody += 'Prezado(a) ' + cNome + ','
	cBody += '</p>								'
	cBody += '<p>'
	cBody += 'Sua solicitação de serviço diverso foi cancelada, Motivo:<br>'
	cBody += '<p><b>' + cMotivo + '</b></p>'
	cBody += '</p>'
	cBody += '<table border="1" cellpadding="3" cellspacing="1" width=97% align=center>'
	cBody += '<tr>'
	cBody += '<td width="10%" class="TableRowBlueDarkMini" align="center" height="14"><b>Data</b></td>'
	cBody += '<td width="15%" class="TableRowBlueDarkMini" align="center" height="14"><b>Cliente</b></td>'
	cBody += '<td width="15%" class="TableRowBlueDarkMini" align="center" height="14"><b>Descrição</b></td>'
	cBody += '<td width="10%" class="TableRowBlueDarkMini" align="center" height="14"><b>Valor (R$)</b></td>'
	cBody += '<td width="25%" class="TableRowBlueDarkMini" align="center" height="14"><b>Numero fluig</b></td>'
	cBody += '<td width="25%" class="TableRowBlueDarkMini" align="center" height="14"><b>Mensagem</b></td>'
	cBody += '</tr>'
	cBody += '<tbody>'
	cBody += '<tr>'
	cBody += '<td width="10%" class="TableRowWhiteMini2" align="center" height="14">' + dtoc(ZC5->ZC5_DATA) + '</td>'
	cBody += '<td width="15%" class="TableRowWhiteMini2" align="center" height="14">' + alltrim(ZC5->ZC5_CLIENT) + '</td>'
	cBody += '<td width="15%" class="TableRowWhiteMini2" align="center" height="14">' + alltrim(ZC5->ZC5_NOMCLI) + '</td>'
	cBody += '<td width="10%" class="TableRowWhiteMini2" align="right" height="14">' + Transform(ZC5->ZC5_VALOR,"@E 9999,999,999.99") + '</td>'
	cBody += '<td width="25%" class="TableRowWhiteMini2" align="right" height="14">' + alltrim(ZC5->ZC5_NUMSOC) + '</td>'
	cBody += '<td width="25%" class="TableRowWhiteMini2" align="left" height="14">' + alltrim(ZC5->ZC5_MSGNOT) + '</td>'
	cBody += '</tr>'
	cBody += '</tbody>'
	cBody += '</table>'
	cBody += '								'
	cBody += '</td>'
	cBody += '</tr>'
	cBody += '<tr>'
	cBody += '</tr>'
	cBody += '</table>'
	cBody += '<p align=center class=style41>Esta mensagem foi gerada automaticamente pelo Sistema.<br></p>'
	cBody += '<p align=center class=style4>&nbsp;</p>'
	cBody += '<p align=center class=style4>&nbsp;</p>'
	cBody += '</td>'
	cBody += '</tr>'
	cBody += '			  '
	cBody += '</table>'
	cBody += ''
	cBody += '</form>'
	cBody += '</body>'
	cBody += '</html>'

	
Return cBody

user function C05A01CO()
	U_CCFGE03('ZC5', ZC5->(recno()))
return

/*/{Protheus.doc} C05A01FM
Rotina para realizar o faturamento manual - Não realiza a transmissão para a prefeitura
@author carlos.henrique
@since 19/02/2018
@version undefined

@type function
/*/
User Function C05A01FM()
Local cSemaforo := "CCA07FAT"

IF ZC5->ZC5_STATUS$"0|1|3"
	//Não permite processamento com mesmo código de semaforo
	If LockByName(cSemaforo,.T.,.T.)
		IF MSGYESNO("Confirma o faturamento manual?")
			RECLOCK("ZC5",.F.)
			ZC5->ZC5_STATUS	:= "0"
			ZC5->(MSUNLOCK())
			
			FWMsgRun(,{|| U_CCA07PRO() },,"Relizando faturamento manual, aguarde..." )
			
			IF ZC5->ZC5_STATUS == "3"
				MSGALERT("Falha no faturamento da nota, consultar log!")
			ELSEIF ZC5->ZC5_STATUS == "2"
				MSGINFO("Faturamento realizado com sucesso!")
			ENDIF
			
			IF ZC5->ZC5_STATUS=="0007"
				MSGALERT("Para filial de campinas a transmissão para prefeitura é manual pela rotina NFSe.")
			ENDIF
			 		
			IF ZC5->ZC5_STATUS=="0060"
				MSGALERT("Para filial de Taubaté a transmissão para prefeitura é manual pela rotina NFSe.")
			ENDIF
			 		
		Endif
		UnLockByName(cSemaforo,.T.,.T.)
	Else
		MSGALERT("Já existe um processamento em execução para o semaforo: "+cSemaforo)
	Endif	
ELSE
	MSGALERT("A nota fical "+ZC5->ZC5_RPSSOC+" já foi faturada!")
ENDIF

RETURN
/*/{Protheus.doc} C05A01CM
Rotina para realizar o cancelamento manual - Não realiza a transmissão para a prefeitura
@author carlos.henrique
@since 19/02/2018
@version undefined

@type function
/*/
User Function C05A01CM()
Local cSemaforo := "CCA07FAT"
Local lSemNota  := .F. 
Local aMsgRet	:= {"","2",""}
Local cDesMot	:= ""
Local lConfirm	:= .F.
Local oDlg		:= nil

IF ZC5->ZC5_STATUS == "8"
	MSGALERT("A nota fical "+ZC5->ZC5_RPSSOC+" já foi cancelada na data:"+DTOC(ZC5->ZC5_DTCANC))
	RETURN
ENDIF

IF ZC5->ZC5_STATUS == "6"
	MSGALERT("A nota fical "+ZC5->ZC5_RPSSOC+" em processo de cancelamento!")
	RETURN
ENDIF

if ZC5->ZC5_STATUS == "P" .OR. ZC5->ZC5_STATUS == "O"
	MSGALERT("Não é possivel realizar o cancelamento sem nota fiscal emitida!")
	RETURN
endif

//Não permite processamento com mesmo código de semaforo
If LockByName(cSemaforo,.T.,.T.)
	 
	IF MSGYESNO("Confirma o cancelamento manual? ")
		
		IF EMPTY(ZC5->ZC5_NOTA)
			lSemNota:= .T.
		ENDIF
		
		RECLOCK("ZC5",.F.)
		ZC5->ZC5_STATUS	:= "5"
		ZC5->(MSUNLOCK())
		
		FWMsgRun(,{|| U_CCA07CAN() },,"Relizando cancelamento manual, aguarde..." )
		
		IF ZC5->ZC5_STATUS == "7"
			MSGALERT("Falha no cancelamento da nota, consultar log!")
		ELSEIF ZC5->ZC5_STATUS == "8"
			IF lSemNota		
			
				cDesMot		:= ZC5->ZC5_DESMOT
				lConfirm	:= .F.
				
				//Realiza loop se não respeitar a regra
				WHILE !lConfirm				
					
					DEFINE MSDIALOG oDlg TITLE "Motivo de Cancelamento" FROM 0,0 TO 200,600 OF oDlg PIXEL
					@ 06,06 TO 90,300 LABEL "Preencher as Informações:" OF oDlg PIXEL
					@ 15, 15 SAY   "RPS:"+ZC5->ZC5_RPSSOC SIZE 45,8 PIXEL OF oDlg
					@ 30, 15 SAY   "Descrição do Motivo de cancelamento:" SIZE 100,8 PIXEL OF oDlg
					@ 38, 15 MSGET cDesMot SIZE 250,10 PICTURE PesqPict("SF3","F3_XDESMOT") PIXEL
					@ 70,250 BUTTON "&Confirma"   SIZE 36,16 PIXEL ACTION EVAL({|| lConfirm:=.T.,oDlg:End()})
					ACTIVATE MSDIALOG oDlg CENTER
					
					IF lConfirm .AND. EMPTY(cDesMot)
						ALERT("Informe o motivo de cancelamento!")
						lConfirm	:= .F.
					ENDIF			
				END
				
				RECLOCK("ZC5",.F.)
				ZC5->ZC5_DESMOT	:= cDesMot
				ZC5->(MSUNLOCK())
						
				aMsgRet	:= {ZC5->ZC5_RPSSOC,;
							"2",;
							ZC5->ZC5_RPSSOC+'|'+;			// RPS SOC
							'|'+;							// Pedido Protheus
							'|'+;							// RPS Protheus
							'|'+;							// Chave NFS-e/NFE
							DTOS(ZC5->ZC5_DTCANC)+'|'+;		// Dt/Hr Emissao NFS-e (Cancelamento)
							'|'+;							// Cod autorização
							"NF CANCELADA|"+CRLF;			// Msg do TSS
							}
				
				//Gera arquivo TXT no diretório RPS
				STATICCALL(CFATE04,C05E04GTXT,aMsgRet)								
			ENDIF
			MSGINFO("Nota cancelada com sucesso!")
		ENDIF
		 		
	Endif
	UnLockByName(cSemaforo,.T.,.T.)
Else
	MSGALERT("Já existe um processamento em execução para o semaforo: "+cSemaforo)
Endif	

RETURN
/*/{Protheus.doc} C05A01GL
Realizar o retorno por lote para SOE
@author carlos.henrique
@since 19/02/2018
@version undefined

@type function
/*/
User Function C05A01GL()
Local cTab	 := ""
Local oFont	 := NIL
Local oDlg	 := NIL
Local oMemo	 := NIL
Local lOk    := .F.
	
Define Font oFont Name "Mono AS" Size 5, 12

Define MsDialog oDlg Title "Informe os codigos SOE seperado por ponto e virgula:" From 3, 0 to 340, 417 Pixel

@ 5, 5 Get oMemo Var cTXTRPS Memo Size 200, 145 Of oDlg Pixel
oMemo:bRClicked := { || AllwaysTrue() }
oMemo:oFont     := oFont

Define SButton From 153, 175 Type  1 Action (lOk:=.T.,oDlg:End()) Enable Of oDlg Pixel 
Activate MsDialog oDlg Center

if lOk
	cTab:= GetNextAlias()
	
	BeginSql Alias cTab				
		SELECT ZC5.R_E_C_N_O_ AS ZC5REC  FROM %TABLE:ZC5% ZC5 WITH (NOLOCK)
		WHERE ZC5_FILIAL=%xfilial:ZC5%
		AND ZC5_RPSSOC IN %EXP:FormatIn(cTXTRPS,";")%
		AND ZC5_STATUS IN ('2','4')
		AND ZC5.D_E_L_E_T_=''									
	EndSql
	//GETLastQuery()[2]
				
	(cTab)->(dbSelectArea((cTab)))                    
	(cTab)->(dbGoTop())                               	
	WHILE (cTab)->(!EOF())
	
		// Posiciona tabela ZC5
		ZC5->(DBGOTO((cTab)->ZC5REC))
		
		U_C05A01GR(.T.)
		
	(cTab)->(dbskip())	
	END
	(cTab)->(dbCloseArea())	
endif
	
RETURN
/*/{Protheus.doc} C05A01GR
Realizar o retorno manual  para SOE
@author carlos.henrique
@since 19/02/2018
@version undefined

@type function
/*/
User Function C05A01GR(lLote)
Local cQryUpd:= ""
Local cTab	 := ""
Local lExec	 := .T.
DEFAULT lLote:= .F.

IF !(lLote)	
	
	IF !(ZC5->ZC5_STATUS$"2,4")
		MSGALERT("O monitoramento de RPS está disponivel apenas no status:"+CRLF+;
				  "Faturamento Realizado\Aguardando Transmissão Prefeitura"+CRLF+;
				  "Faturamento Realizado\Transmissão Prefeitura Realizada")
		RETURN
	ENDIF
	
	lExec:= MSGYESNO("Confirma a execução do retorno para o SOE ?")
	
ENDIF

IF lExec

	IF ZC5->ZC5_FILIAL=="0006"
	
		//Tratamento AUTONFE
		cQryUpd:= " UPDATE "+RETSQLNAME("SF3")+" SET F3_CODRET='T',F3_DESCRET='',F3_XFLGRET=''"
		cQryUpd+= " WHERE F3_FILIAL+F3_SERIE+F3_NFISCAL IN("
		cQryUpd+= " 	SELECT ZC5_FILIAL+ZC5_SERIE+ZC5_NOTA FROM "+RETSQLNAME("ZC5")
		cQryUpd+= " 	WHERE ZC5_FILIAL='"+ZC5->ZC5_FILIAL+"'"	
		cQryUpd+= " 	AND ZC5_RPSSOC='"+ZC5->ZC5_RPSSOC+"'"
		cQryUpd+= " 	AND ZC5_STATUS='4'"		
		cQryUpd+= " )"
	
	
		IF (TCSQLEXEC(cQryUpd)< 0)
			MSGALERT("Falha ao monitorar:"+TCSQLError()) 
		ELSE
			MSGINFO("Monitotamento em andamento, aguarde!")
		ENDIF	
	
	ELSEIF ZC5->ZC5_FILIAL=="0003"
	
		cTab:= GetNextAlias()
		
		BeginSql Alias cTab	
			%NOPARSER%
			SELECT SF3.R_E_C_N_O_ AS SF3REC,SF2.R_E_C_N_O_ AS SF2REC,SC5.R_E_C_N_O_ AS SC5REC  FROM %TABLE:ZC5% ZC5 WITH (NOLOCK)
			INNER JOIN %TABLE:SC5% SC5 WITH (NOLOCK) ON C5_FILIAL=ZC5_FILIAL
				AND C5_XRPSSOC=ZC5_RPSSOC
				AND C5_CLIENT=ZC5_CLIENT
				AND C5_LOJACLI=ZC5_LOJA
				AND SC5.D_E_L_E_T_=''
			INNER JOIN %TABLE:SF2% SF2 ON F2_FILIAL=C5_FILIAL 
				AND F2_SERIE=C5_SERIE
				AND F2_DOC=C5_NOTA
				AND F2_CLIENT=C5_CLIENT
				AND F2_LOJA=C5_LOJACLI
				AND SF2.D_E_L_E_T_=''
			INNER JOIN %TABLE:SF3% SF3 ON F2_FILIAL=F3_FILIAL 
				AND F3_SERIE=F2_SERIE
				AND F3_NFISCAL=F2_DOC
				AND F3_CLIENT=F2_CLIENT
				AND F3_LOJA=F2_LOJA 
				AND SF3.D_E_L_E_T_=''
			WHERE ZC5_FILIAL=%xfilial:ZC5%
			AND ZC5_RPSSOC=%EXP:ZC5->ZC5_RPSSOC%
			AND ZC5.D_E_L_E_T_=''									
		EndSql
		//GETLastQuery()[2]
					
		(cTab)->(dbSelectArea((cTab)))                    
		(cTab)->(dbGoTop())                               	
		IF (cTab)->(!EOF())
		
			// Posiciona tabela SF3
			SF3->(DBGOTO((cTab)->SF3REC))
			// Posiciona tabela SF2
			SF2->(DBGOTO((cTab)->SF2REC))
			// Posiciona tabela SC5
			SC5->(DBGOTO((cTab)->SC5REC))											
		
			//Gera mensagem de retorno ESB
			U_CFATE04()	
		ENDIF
		(cTab)->(dbCloseArea())	
	ELSE
		//Tratamento AUTONFSE
		cQryUpd:= " UPDATE "+RETSQLNAME("SF3")+" SET F3_CODRSEF='T',F3_CODRET='',F3_XFLGRET=''"
		cQryUpd+= " WHERE F3_FILIAL+F3_SERIE+F3_NFISCAL IN("
		cQryUpd+= " 	SELECT ZC5_FILIAL+ZC5_SERIE+ZC5_NOTA FROM "+RETSQLNAME("ZC5")
		cQryUpd+= " 	WHERE ZC5_FILIAL='"+ZC5->ZC5_FILIAL+"'"
		cQryUpd+= " 	AND ZC5_RPSSOC='"+ZC5->ZC5_RPSSOC+"'"
		cQryUpd+= " 	AND ZC5_STATUS='4'"	
		cQryUpd+= " )"
		
		IF (TCSQLEXEC(cQryUpd)< 0)
			MSGALERT("Falha ao gerar retorno SOE:"+TCSQLError()) 
		ELSE
			MSGINFO("Retorno em andamento, aguarde!")
		ENDIF					
	ENDIF		 		
Endif

RETURN

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C05A01ME
Função para manutenção do e-mail do cliente.
@author  	Danilo José Grodzicki
@since     	08/06/2018
@version  	P.12      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function C05A01ME()

Local oDlg
Local oSay
Local oGet
Local oPanel
//Local oSayMsg
Local oButtonCon
Local oButtonCan

Local cEmail    := space(100)
//Local oModelAtv := FWModelActive()
//Local oStruZC5  := FWFormStruct(1, "ZC5")  

if !((Empty(ZC5->ZC5_EMAIL) .or. ZC5->ZC5_WF == "2") .and. ZC5->ZC5_STATUS == "4")
	MsgStop("Alteração não permitida. Já existe e-mail cadastrado.","ATENÇÃO")
else
	DEFINE MSDIALOG oDlg TITLE "Manutenção do E-mail do Cliente" FROM 000,000 TO 180,750 COLORS 0,16777215 PIXEL
		
		@ 014,010 SAY oSay PROMPT "E-mail do Cliente:" SIZE 065,010 OF oDlg COLORS 0,16777215 PIXEL
		
		@ 012,060 MSGET oGet VAR cEmail SIZE 300,010 OF oDlg COLORS 0,16777215 PIXEL
		
		oPanel:= tPanel():New(40,90,'Utilizar o ";" (ponto e vírgula) para separar um e-mail do outro e-mail.',oDlg,,.T.,,CLR_RED,,200,015,,)						
		
		@ 065,120 BUTTON oButtonCon PROMPT "Confirma" SIZE 041,014 OF oDlg PIXEL ACTION (iif(ValEmail(cEmail),oDlg:End(),.F.))
		@ 065,190 BUTTON oButtonCan PROMPT "Cancela"  SIZE 041,014 OF oDlg PIXEL ACTION (oDlg:End())
		
	ACTIVATE MSDIALOG oDlg CENTERED
endif

Return(.T.)

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ValEmail
Função para manutenção do e-mail do cliente validação tela e-mail.
@author  	Danilo José Grodzicki
@since     	11/06/2018
@version  	P.12      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------

Static Function ValEmail(cEmail)

Local nI

Local aDados   := {}
Local aAreaSA1 := SA1->(GetArea())

if Empty(cEmail)
	MsgStop("E-mail do cliente está em branco.","ATENÇÃO")
	Return(.F.)
endif

DbSelectArea("SA1")
SA1->(DbSetOrder(01))

aDados := Separa(cEmail,";",.T.)
for nI = 1 to Len(aDados)
	if !ValMail(aDados[nI])
		Return(.F.)
	endif
next

If RecLock("ZC5",.F.)
	ZC5->ZC5_EMAIL := AllTrim(cEmail)
	ZC5->ZC5_WF := ""
	ZC5->(MsUnlock())
endif

if SA1->(DbSeek(xFilial("SA1")+ZC5->ZC5_CLIENT+ZC5->ZC5_LOJA))
	If RecLock("SA1",.F.)
		SA1->A1_EMAIL := AllTrim(cEmail)
		SA1->(MsUnlock())
	endif
endif

RestArea(aAreaSA1)

MsgInfo("E-mail gravado com sucesso.","ATENÇÃO")

Return(.T.)

/*/{Protheus.doc} ValMail
Valida e-mail do cliente
@author Felipe Queiroz
@since 29/05/2018
@version undefined
@type function
/*/
Static Function ValMail(cEmailCli)

Local cLit   := ' {}()<>[]|\/&*$ %?!^~`,;:=#'
Local lRet   := .T.
Local nResto := 0
Local nI
Local vEmail := ''
	
	vEmail := AllTrim( cEmailCli )
	
	For nI := 1 To Len( cLit )
		If At( SubStr( cLit, nI, 1 ), vEmail )  >   0
			ApMsgStop( 'Existe um caracter invalido para e-mail: ' + cEmailCli, 'ATENÇÃO' )
			lRet   := .F.
			Exit
		EndIf
	Next
	
	If lRet
		If ( nResto := At( "@", vEmail ) ) > 0 .AND. At( "@", Right( vEmail, Len( vEmail ) - nResto ) ) == 0
			If ( nResto := At( ".", Right( vEmail, nResto ) ) ) == 0
				lRet := .F.
			EndIf
		Else
			ApMsgStop( 'Endereço de e-mail invalido: ' + cEmailCli, 'ATENÇÃO' )
			lRet := .F.
		EndIf
	EndIf
	
Return lRet
