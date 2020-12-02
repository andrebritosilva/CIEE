#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#Include 'tbiconn.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} CFINA99
Retorno de arquivos CNAB a receber a mais de 89 dias

@author André Brito
@since 03/08/2020
@version P12
/*/
//-------------------------------------------------------------------

User Function CFINA99()

Local oBrowse

oBrowse := FWMBrowse():New()
oBrowse:SetAlias('ZCO')
oBrowse:SetDescription('Retorno CNAB a Receber')

oBrowse:Addlegend("ZCO_FLTRAN == ' '"  , "BR_AMARELO" , "Não efetuada transferência")
oBrowse:Addlegend("ZCO_FLTRAN == 'S'"  , "BR_VERDE"	  , "Transferência efetuada")

oBrowse:Activate()

Return NIL

//-------------------------------------------------------------------

Static Function MenuDef()

Local aRotina := {}

ADD OPTION aRotina TITLE 'Visualizar'       ACTION 'VIEWDEF.CFINA99' OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE 'Trocar Carteira'  ACTION 'U_CFIN99TRA'     OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE 'Enviar WF'        ACTION 'U_CFIN99WF'      OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE 'Legenda'          ACTION 'U_CFIN99LEG'   OPERATION 6 ACCESS 0

Return aRotina

//-------------------------------------------------------------------

Static Function ModelDef()

// Cria a estrutura a ser usada no Modelo de Dados

Local oStruZCO := FWFormStruct( 1, 'ZCO', /*bAvalCampo*/,/*lViewUsado*/ )
Local oModel

oModel := MPFormModel():New('CFINA99M', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

oModel:AddFields( 'ZCOMASTER', /*cOwner*/, oStruZCO, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

// Adiciona a descricao do Modelo de Dados
oModel:SetDescription( 'CNAB a Receber - Boletos fora do prazo' )

// Adiciona a descricao do Componente do Modelo de Dados
oModel:GetModel( 'ZCOMASTER' ):SetDescription( 'CNAB a Receber' )

Return oModel

//-------------------------------------------------------------------

Static Function ViewDef()

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel   := FWLoadModel( 'CFINA99' )
// Cria a estrutura a ser usada na View
Local oStruZA0 := FWFormStruct( 2, 'ZCO' )

Local oView
//Local cCampos := {}

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados ser utilizado
oView:SetModel( oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField( 'VIEW_CAB', oStruZA0, 'ZCOMASTER' )

Return oView

//-------------------------------------------------------------------
/*/{Protheus.doc} CFIN99WF

Envia WF para usuário que incluiu o título a receber

@author André Brito
@since 03/08/2020
@version P12
/*/
//-------------------------------------------------------------------

User Function CFIN99WF()

Local aArea    := GetArea()
Local oHtml
Local cHtml    := ""
Local cAssunto := "Títulos em aberto"
Local cBody	   := "Segue em anexo os boletos em aberto a mais de 89 dias: " 
Local cEmail   := ""
Local cAttach  := ""
Local cItens   := ""
Local aUsers   := U_CFIN99USR()
Local cQuery   := ""
Local cAliAux  := ""
Local nx       := 0
Local lJob	   := GetRemoteType() == -1 
Local lEnvia   := .F.

oHtml := TWFHtml():New("\workflow\html\wfcr.htm")

For nx := 1 To Len (aUsers) 

	cEmail := aUsers[nx]
	
	cAliAux  := GetNextAlias()
	
	cQuery := "SELECT R_E_C_N_O_ FROM " 
	cQuery += RetSqlName("ZCO") + " ZCO "
	cQuery += "WHERE  ZCO_FLTRAN = ' ' " 
    cQuery += "AND ZCO_XNOME ='" + aUsers[nx] + "' " 
    cQuery += "AND D_E_L_E_T_ = ''" 
    
    cQuery := ChangeQuery(cQuery) 
 
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliAux,.T.,.T.)

    (cAliAux)->(dbGoTop())

    Do While (cAliAux)->(!Eof())
    
    	ZCO->(DbGoto((cAliAux)->R_E_C_N_O_))
    	
    	lEnvia := .T.
    	
		cItens += '<tr class="texto" style="height: 15px;">'
		cItens += '<td>' + ZCO->ZCO_NUM + '</td>'
		cItens += '<td>' + ZCO->ZCO_PREFIX + '</td>'
		cItens += '<td>' + ZCO->ZCO_PARCEL + '</td>'
		cItens += '<td>' + ZCO->ZCO_CLIENT + '</td>'
		cItens += '<td>' + ZCO->ZCO_LOJA + '</td>'
		cItens += '<td>' + DTOC(ZCO->ZCO_EMISSA) + '</td>'
		cItens += '<td>' + DTOC(ZCO->ZCO_VENCTO) + '</td>'
		cItens += '<td>' + DTOC(ZCO->ZCO_VENCRE) + '</td>'
		cItens += '<td>R$' + Transform (ZCO->ZCO_VALOR,"@E 99,999,999,999.99") + '</td>'
		cItens += '<td>' + Alltrim(ZCO->ZCO_HIST) + '</td>'
		cItens += '</tr>'
		
		(cAliAux)->(DbSkip())
		
	EndDo
	
	If lEnvia
		oHtml:cBuffer := StrTran( oHtml:cBuffer, "%periodo%" , DTOC(dDataBase))
		oHtml:cBuffer := StrTran( oHtml:cBuffer, "!t2.cItens!" , cItens)
		
		cHtml := oHtml:cBuffer
		
		if !ExistDir("\workflow\Temp")
			MakeDir("\workflow\Temp")
		EndIf
		
		
		If MemoWrite("\workflow\Temp\wfcr.HTML", cHtml)
			cAttach := "\workflow\Temp\wfcr.HTML"
			lRetorno := U_CFIN99MAIL(cAssunto, cBody, cEmail,cAttach,,,,,,,,,,lJob)	
		Endif
		
		(cAliAux)->(dbCloseArea())
		
	EndIf

Next

RestArea(aArea)

Return cHtml


//-------------------------------------------------------------------
/*/{Protheus.doc} CFIN99MAIL

Envia WF para usuário que incluiu o título a receber

@author André Brito
@since 03/08/2020
@version P12
/*/
//-------------------------------------------------------------------

User Function CFIN99MAIL(cAssunto, cBody, cEmail,cAttach,cMailConta,cUsuario,cMailServer,cMailSenha,lMailAuth,lUseSSL,lUseTLS,cCopia,cCopiaOculta,lJob)
	
Local nMailPort		:= 0
Local nAt			:= ""
Local lRet 			:= .T.
Local oServer		:= TMailManager():New()
Local aAttach		:= {}
Local nLoop			:= 0

Default cAttach		:= ''
Default cMailConta	:= SuperGetMV("MV_RELACNT")
Default cUsuario	:= SubStr(cMailConta,1,At("@",cMailConta)-1)
Default cMailServer	:= AllTrim(SuperGetMv("MV_RELSERV"))//"smtp.xxxx.com"
Default cMailSenha	:= SuperGetMV("MV_RELPSW")
Default lMailAuth	:= .T.//SuperGetMV("MV_RELAUTH",,.F.)
Default lUseSSL		:= SuperGetMV("MV_RELSSL",,.F.)
Default lUseTLS		:= SuperGetMV("MV_RELTLS",,.F.)
Default cCopia		:= ''
Default lJob        := .F.

nAt			:= At(":",cMailServer)

oServer:SetUseSSL(lUseSSL)
oServer:SetUseTLS(lUseTLS)


// Tratamento para usar a porta quando informada no mailserver
If nAt > 0
	nMailPort	:= VAL(SUBSTR(ALLTRIM(cMailServer),At(":",cMailServer) + 1,Len(ALLTRIM(cMailServer)) - nAt))
	cMailServer	:= SUBSTR(ALLTRIM(cMailServer),1,At(":",cMailServer)-1)
	oServer:Init("", cMailServer, cMailConta, cMailSenha,0,nMailPort)
Else
	oServer:Init("", cMailServer, cMailConta, cMailSenha,0,587)
EndIf

If oServer:SMTPConnect() != 0
	lRet := .F.
	If !lJob
		alert("Servidor não conectou!"+CRLF+"Servidor: "+cMailServer+CRLF+"Verifique os dados cadastrados no Configurador."+CRLF+"Acesse Ambiente -> E-mail/Proxy -> Configurar")
	Else
		Conout("Servidor não conectou!")
	EndIf
EndIf

If lRet
	If lMailAuth
		
		//Tentar com conta e senha
		If oServer:SMTPAuth(cMailConta, cMailSenha) != 0
			
			//Tentar com usuário e senha
			If oServer:SMTPAuth(cUsuario, cMailSenha) != 0
				lRet := .F.
				If !lJob
					alert("Autenticação do servidor não funcionou!"+CRLF+ "Conta: "+cMailConta+".  Usuário: "+cUsuario+".  Senha: "+cMailSenha+"."+CRLF+"Verifique os dados cadastrados no Configurador."+CRLF+"Acesse Ambiente -> E-mail/Proxy -> Configurar")
				Else
					Conout("Autenticação do servidor não funcionou!")
				EndIf
			EndIf
			
		EndIf
		
	EndIf
EndIf

If lRet
	
	oMessage				:= TMailMessage():New()
	
	oMessage:Clear()
	oMessage:cFrom			:= cMailConta
	oMessage:cTo			:= cEmail
	oMessage:cCc			:= cCopia
	oMessage:cBCC			:= cCopiaOculta
	oMessage:cSubject		:= cAssunto
	oMessage:cBody			:= cBody
	
	//oMessage:AttachFile( cAttach )
	aAttach	:= StrTokArr(cAttach, ';')
	
	For nLoop := 1 To Len(aAttach)
		oMessage:AttachFile( aAttach[nLoop] )
	Next
	//Envia o e-mail
	
	nErro := oMessage:Send( oServer )
	If( nErro != 0 )
		
		If !lJob
			MsgInfo( oServer:GetErrorString( nErro ) ,"Não enviou o e-mail.")
		Else
			conout( "Não enviou o e-mail.", oServer:GetErrorString( nErro ) )
		EndIf
		
		Return
	EndIf
	
EndIf
 
//Desconecta do servidor
oServer:SMTPDisconnect()
if lRet 
	If !lJob
	
		MsgInfo("Email enviado com sucesso!","Relação Títulos a Receber")
		
	Else
		U_CFIN99TRA(lJob)
		conout( "Email enviado com sucesso" )
	EndIf
Else
	If !lJob
		Alert("Email não enviado!")
	Else
		conout( "Email não enviado!" )
	EndIf
Endif

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CFIN99TRA

Efetua transferência entre carteiras

@author André Brito
@since 11/08/2020
@version P12
/*/
//-------------------------------------------------------------------

User function CFIN99TRA(lJob)

Local aTit       := {}
Local cPrefixo   := ""
Local cNumero    := ""
Local cParcela   := ""
Local cTipo      := ""
Local cBanco     := ""
Local cAgencia   := ""
Local cConta     := ""
Local cSituaca   := ""
Local cNumBco    := ""
Local cCarteira  := ""
Local nDesconto  := 0
Local nValCred   := 0
Local nVlIof     := 0
Local dDataMov   := dDataBase
Local cDados     := SuperGetMv("CI_BCOCART",.F.,"")
Local aCont      := StrTokArr( cDados, ";" ) //[1]Banco [2]Agencia [3]Conta [4]Digito [5]Carteira
//-- Variáveis utilizadas para o controle de erro da rotina automática
Local aErroAuto  := {}
Local cErroRet   := ""
Local nCntErr    := 0

Default lJob     := .F.

Private lMsErroAuto    := .F.
Private lMsHelpAuto    := .T.
Private lAutoErrNoFile := .T.

cBanco     := aCont[1]
cAgencia   := aCont[2]
cConta     := aCont[3]
cNumBco    := aCont[4]
cCarteira  := aCont[5]

//Chave do título

aAdd(aTit, {"E1_PREFIXO" , PadR(ZCO->ZCO_PREFIXO , TamSX3("E1_PREFIXO")[1]) ,Nil})
aAdd(aTit, {"E1_NUM"     , PadR(ZCO->ZCO_NUM     , TamSX3("E1_NUM")[1]) ,Nil})
aAdd(aTit, {"E1_PARCELA" , PadR(ZCO->ZCO_PARCELA , TamSX3("E1_PARCELA")[1]) ,Nil})
aAdd(aTit, {"E1_TIPO"    , PadR(ZCO->ZCO_TIPO    , TamSX3("E1_TIPO")[1]) ,Nil})

//Informações bancárias

aAdd(aTit, {"AUTDATAMOV" , dDataMov ,Nil})
aAdd(aTit, {"AUTBANCO"   , PadR(cBanco   ,TamSX3("A6_COD")[1])     ,Nil})
aAdd(aTit, {"AUTAGENCIA" , PadR(cAgencia ,TamSX3("A6_AGENCIA")[1]) ,Nil})
aAdd(aTit, {"AUTCONTA"   , PadR(cConta   ,TamSX3("A6_NUMCON")[1])  ,Nil})
aAdd(aTit, {"AUTSITUACA" , PadR(cSituaca ,TamSX3("E1_SITUACA")[1]) ,Nil})
aAdd(aTit, {"AUTNUMBCO"  , PadR(cNumBco  ,TamSX3("E1_NUMBCO")[1])  ,Nil})

MSExecAuto({|a, b| FINA060(a, b)}, 2,aTit)

If lMsErroAuto

	aErroAuto := GetAutoGRLog()
	
	For nCntErr := 1 To Len(aErroAuto)
	
		cErroRet += aErroAuto[nCntErr]
	
	Next
	
	Conout(cErroRet)

EndIf

Return

User Function CFIN99LEG()

BrwLegenda("Status Transferência","Legenda", { {"BR_AMARELO"     , OemToAnsi("Não efetuada transferência")},;
											{"BR_VERDE"  , OemToAnsi("Transferência efetuada")       }})

Return Nil

User Function CFIN99USR()

Local aArea    := GetArea()
Local cQuery   := ""
Local cAliAux  := GetNextAlias()
Local aUsers   := {}

cQuery := "SELECT ZCO_XNOME FROM " 
cQuery += RetSqlName("ZCO") + " ZCO "
cQuery += "WHERE  ZCO_FLTRAN = '' " 
cQuery += "AND D_E_L_E_T_ = '' " 
cQuery += "GROUP  BY ZCO_XNOME" 

cQuery := ChangeQuery(cQuery) 
 
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliAux,.T.,.T.)

(cAliAux)->(dbGoTop())

Do While (cAliAux)->(!Eof())

	AADD(aUsers,(cAliAux)->ZCO_XNOME)
	
	(cAliAux)->(DbSkip())

EndDo

(cAliAux)->(dbCloseArea())

RestArea(aArea)

Return aUsers