#Include 'Protheus.ch'

/*/{Protheus.doc} F200FIM
Ponto de entrada no fim do processamento do CNAB de retorno das cobranças
@author carlos.henrique
@since 15/10/2020
@version undefined
@type function
/*/
USER FUNCTION F200FIM()
Local nMv		:= 0
LOCAL cBkpRPG	:= ""
Local aAuxArq	:= {}
Local cDrive	:= ""
Local cDir		:= ""
Local cNome		:= ""
Local cExt		:= ""
Private aMvPar	:= {}  

//Realizar o backup dos parametros
For nMv := 1 To 40
    aadd( aMvPar, &( "MV_PAR" + StrZero( nMv, 2, 0 ) ) )
Next nMv

//Relatório de ocorrências 
U_CFINR090()

//Restaura parametros da rotina
For nMv := 1 To LEN(aMvPar)
    &( "MV_PAR" + StrZero( nMv, 2, 0 ) ) := aMvPar[nMv]
Next nMv

//Movimenta arquivo processado para o diretório de backup
SplitPath(MV_PAR04, @cDrive, @cDir, @cNome, @cExt )

cBkpRPG	:= cDir + "\backup\"

IF FILE(MV_PAR04)
	aAuxArq:= StrTokArr(MV_PAR04,"\",.F.)
	IF !EMPTY(aAuxArq)
		//Move arquivo para o diretorio de backup			
		If __CopyFile(MV_PAR04,cBkpRPG+aAuxArq[LEN(aAuxArq)])
			If nHdlBco > 0
				FCLOSE(nHdlBco)				
				FERASE(MV_PAR04)
			ELSE	
				FERASE(MV_PAR04)
			Endif			
		EndIF			
	ENDIF	
ENDIF

//Envia e-mail dos titulos adicionados em carteira após 89 dias
EnvMailCart()

RETURN 

//-------------------------------------------------------------------
/*/{Protheus.doc} EnvMailCart

Envia e-mail dos titulos removidos de cobrança e adicionado em carteira 

@author André Brito
@since 03/08/2020
@version P12
/*/
//-------------------------------------------------------------------

Static Function EnvMailCart()
Local aArea    := GetArea()
Local oHtml
Local cHtml    := ""
Local cAssunto := "Títulos em Carteira CIEE"
Local cBody	   := "Segue em anexo titulos abertos a mais de 89 dias que foram adicionados na Carteira CIEE. "
Local cEmail   := TRIM(SuperGetMv("CI_GRPCART" ,.F.,"carlos.henrique@totvs.com.br")) //grupo de e-mail de titulos adicionados em carteira
Local cAttach  := ""
Local cItens   := ""
Local cQuery   := ""
Local cAliAux  := GetNextAlias()
Local lJob	   := GetRemoteType() == -1 


cQuery := "SELECT R_E_C_N_O_ FROM " 
cQuery += RetSqlName("ZCO") + " ZCO "
cQuery += "WHERE  ZCO_FLTRAN = ' ' " 
cQuery += "AND D_E_L_E_T_ = ''" 

cQuery := ChangeQuery(cQuery) 

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliAux,.T.,.T.)

(cAliAux)->(dbGoTop())

if (cAliAux)->(!Eof())
	
	oHtml := TWFHtml():New("\workflow\html\wfcr.htm")

	Do While (cAliAux)->(!Eof())

		ZCO->(DbGoto((cAliAux)->R_E_C_N_O_))

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

		RECLOCK("ZCO",.F.)
			ZCO_FLTRAN:= "X"
		MSUNLOCK()
		
	(cAliAux)->(DbSkip())    
	EndDo

	oHtml:cBuffer := StrTran( oHtml:cBuffer, "!t2.cItens!" , cItens)

	cHtml := oHtml:cBuffer

	if !ExistDir("\workflow\Temp")
		MakeDir("\workflow\Temp")
	EndIf

	If MemoWrite("\workflow\Temp\wfcr.HTML", cHtml)
		cAttach := "\workflow\Temp\wfcr.HTML"
		ENVMAIL(cAssunto, cBody, cEmail,cAttach,,,,,,,,,,lJob)	
	Endif

Endif

(cAliAux)->(dbCloseArea())

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

Static Function ENVMAIL(cAssunto, cBody, cEmail,cAttach,cMailConta,cUsuario,cMailServer,cMailSenha,lMailAuth,lUseSSL,lUseTLS,cCopia,cCopiaOculta,lJob)
	
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
		MsgInfo("Email enviado com sucesso!")
	Else
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
