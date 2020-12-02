#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CFINA95
Cadastro Unidade CIEE
@author  	Marcelo Moraes
@since     	04/06/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CFINA95()    
Local oBrowse := FwMBrowse():New()

oBrowse:SetAlias("ZCN")
oBrowse:SetDescription("Cadastro Unidades CIEE ") 
oBrowse:DisableDetails() 

// Ativação da Classe
oBrowse:Activate()						

RETURN
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina de definição do menu
@author  	Marcelo Moraes
@since     	04/06/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function MenuDef()

Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.CFINA95" OPERATION 2 ACCESS 0 
ADD OPTION aRotina TITLE "Importa Kairós" ACTION "U_C6A95IMP" OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Alterar" ACTION "VIEWDEF.CFINA95" OPERATION 4 ACCESS 0

Return(aRotina)
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina de definição do MODEL
@author  	Marcelo Moraes
@since     	04/06/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function ModelDef()

Local oStruZCN 	:= FWFormStruct(1, "ZCN")  
Local oModel   	:= MPFormModel():New( 'CFINA95MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

oModel:AddFields("ZCNMASTER", /*cOwner*/, oStruZCN)
oModel:SetPrimaryKey({"ZCN_FILIAL","ZCN_CODIGO"})
oModel:SetDescription("Cadastro Unidade - CIEE")

Return oModel
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina de definição do VIEW
@author  	Marcelo Moraes
@since     	04/06/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function ViewDef()

Local oView    	:= FWFormView():New()
Local oStruZCN 	:= FWFormStruct( 2, "ZCN")  
Local oModel   	:= FWLoadModel("CFINA95")           	

oView:SetModel(oModel)
oView:AddField("VIEW_ZCN", oStruZCN, "ZCNMASTER")

oView:CreateHorizontalBox("SUPERIOR", 100)

oView:SetOwnerView("VIEW_ZCN", "SUPERIOR")

oView:EnableTitleView('VIEW_ZCN','Detalhe Unidade' )

Return oView

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C6A95IMP
Rotina de importação e atualização de unidades do Kairós
@author  	carlos.henrique
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------

User function C6A95IMP()
Local aParam:={}

Aadd(aParam,{1,'Unidade de' ,0,"@E 999999","","","",20,.T.})
Aadd(aParam,{1,'Unidade Até',0,"@E 999999","","","",20,.T.})

If Parambox(aParam,'Informe os parametros de atualização ?')

	FWMsgRun(,{|| U_C6A95PRO( MV_PAR01, MV_PAR02) },,"Relizando importação de unidades do Kairós, aguarde..." )

	MSGINFO("Processo de importação finalizado!!")

endif

Return

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C6A95PRO
Rotina de importação e atualização de unidades do Kairós
@author  	carlos.henrique
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------

User Function C6A95PRO( nUniDe, nUniAte)
Local nCnta:= 0
Local nCntb:= 0
Local cJson:= ""
Local oJson:= nil
Local cMApo:= ""
Local cCodUni:= ""
Local cItens := ""
Local lTemItens := .F.
Local lLock:= .F.

FOR nCnta:=nUniDe to nUniAte
	
	cJson:= C6A95UNI( CVALTOCHAR(nCnta) )

	IF !EMPTY(cJson)
		oJson:= JsonObject():new()
		oJson:fromJson(cJson)   
		
		cMApo:= ""
		FOR nCntb:=1 to LEN(oJson["emailApoio"])
			cMApo+= oJson["emailApoio"][nCntb]+ ";"
		NEXT

		cCodUni:= AVKEY(oJson:GetJsonText("codigo"),"ZCN_CODIGO")

		lLock:= !ZCN->(DBSEEK(XFILIAL("ZCN")+cCodUni))

		RECLOCK("ZCN",lLock)
			ZCN_FILIAL:= XFILIAL("ZCN")
			ZCN_CODIGO:= oJson:GetJsonText("codigo")
			ZCN_CEP   := oJson["endereco"]:GetJsonText("cep")
			ZCN_BAIRRO:= DecodeUTF8(AllTrim(oJson["endereco"]:GetJsonText("bairro")))
			ZCN_CIDADE:= DecodeUTF8(AllTrim(oJson["endereco"]:GetJsonText("cidade")))
			ZCN_NUMERO:= oJson["endereco"]:GetJsonText("numero")
			ZCN_UF    := oJson["endereco"]:GetJsonText("estado")
			ZCN_COMPL := DecodeUTF8(AllTrim(oJson["endereco"]:GetJsonText("complemento")))
			ZCN_END   := DecodeUTF8(AllTrim(oJson["endereco"]:GetJsonText("logradouro")))
			ZCN_TPEND := DecodeUTF8(AllTrim(oJson["endereco"]:GetJsonText("tipoLogradouro")))
			ZCN_DLOCAL:= DecodeUTF8(AllTrim(oJson:GetJsonText("descricaoLocal")))
			ZCN_CODGER:= oJson:GetJsonText("codigoGerencia")
			ZCN_MAILRE:= oJson["responsavel"]:GetJsonText("email")
			ZCN_NOMRE := DecodeUTF8(AllTrim(oJson["responsavel"]:GetJsonText("nome")))
			ZCN_NRERED:= DecodeUTF8(AllTrim(oJson["responsavel"]:GetJsonText("nomeReduzido")))
			ZCN_SITUAC:= iif(oJson["situacao"],"1","2")
			ZCN_CNPJ  := oJson:GetJsonText("cnpj")
			ZCN_DELOAB:= DecodeUTF8(AllTrim(oJson:GetJsonText("descricaoLocalAbreviada")))
			ZCN_FONE  := oJson:GetJsonText("telefone")
			ZCN_FOCOBR:= oJson:GetJsonText("telefoneCobranca")
			ZCN_MAILAP:= cMApo
// Retirada gravação dos campos conforme solicitado no Card 324
//            ZCN_CRESTA:= oJson:GetJsonText("crEstagio")
//            ZCN_CRPRES:= oJson:GetJsonText("crProcessoEspecial")
//            ZCN_CRAPRC:= oJson:GetJsonText("crAprendizCapacitador")
//            ZCN_CRAPRE:= oJson:GetJsonText("crAprendizEmpregador")
//            ZCN_CRSEGU:= oJson:GetJsonText("crSeguro")
			ZCN_MOEND := oJson:GetJsonText("mostrarEndereco")
		MSUNLOCK()

		if lLock  // Inclusão de uma nova unidade
			if !lTemItens
				lTemItens := .T.
				cItens := '<tr style="text-align:left">'
			else
				cItens += '<tr style="text-align:left">'
			endif
			cItens += '<td>' + AllTrim(ZCN->ZCN_CODIGO) + '</td>'
			cItens += '<td>' + AllTrim(ZCN->ZCN_CNPJ) + '</td>'
			cItens += '<td>' + AllTrim(ZCN->ZCN_DLOCAL) + '</td>'
			cItens += '</tr>'
		endif

		FreeObj(oJson)	 
	ENDIF
Next

// Envia e-mail informando o cadastramento de uma nova unidade
if lTemItens
	U_C6A95EMA(cItens)
endif

return

/*/{Protheus.doc} C6A95UNI
Rotina de integração das unidades Kairos
@author carlos.henrique
@since 19/03/2019
@version undefined
@type function
/*/
STATIC FUNCTION C6A95UNI(cIDUnCIEE)

Local cRet      := " "
Local cUrlServ 	:= ALLTRIM(GetMv("CI_KAIROS",.F.,"https://api.hmg.ciee.org.br"))  // URL do serviço
Local cPath     := ALLTRIM(GetMv("CI_PATHUN",.F.,"/unit/unidades-ciee/"))         // Path
Local oRest 	:= Nil
Local aHeader   := {}
Local cToken	:= U_CINTK12() //Consulta Token de autenticação

IF EMPTY(cToken)
	RETURN " "
ENDIF

oRest := FWRest():New(cUrlServ)

aAdd(aHeader, 'Content-Type: application/json' )
aAdd(aHeader, 'Authorization: Bearer ' + cToken )

oRest:setPath(cPath+alltrim(cIDUnCIEE))

If oRest:GET(aHeader)
	cRet := oRest:GetResult()
Endif

Return(cRet)

/*/{Protheus.doc} C6A95EMA
Envia e-mail informando o cadastramento de uma nova unidade
@author danilo.grodzicki
@since 25/11/2020
@version 12.1.25
@param cMsg
@type user function
/*/
User Function C6A95EMA(cItens)

Local cMsg

Local oMail    := Nil
Local oMessage := Nil

Local nErro  := 0
Local cPass  := AllTrim(WF7->WF7_AUTSEN)
Local cEmail := AllTrim(WF7->WF7_AUTUSU)

Local cLinkLogo	:= GetNewPar("CI_LOGOWF","")

oMail := TMailManager():New()

oMail:SetUseSSL(.F.)

oMail:Init( ALLTRIM(WF7->WF7_POP3SR), AllTrim(WF7->WF7_SMTPSR) , AllTrim(WF7->WF7_AUTUSU), AllTrim(WF7->WF7_AUTSEN), WF7->WF7_POP3PR ,WF7->WF7_SMTPPR )

oMail:SetSmtpTimeOut(WF7->WF7_TEMPO)

nErro := oMail:SmtpConnect()
if nErro <> 0
	oMail:SMTPDisconnect()
	U_uCONOUT("C6A95EMAIL - " + DtoC(Date()) + " - " + Time() + " - FALHA ENVIO EMAIL NOVA UNIDADE TABELA ZCN.")
	Return(.F.)
Endif

nErro := oMail:SmtpAuth(cEmail,cPass)
If nErro <> 0
	oMail:SMTPDisconnect()
	U_uCONOUT("C6A95EMAIL - " + DtoC(Date()) + " - " + Time() + " - FALHA ENVIO EMAIL NOVA UNIDADE TABELA ZCN")
	Return(.F.)
Endif

cMsg := '<html>'
cMsg += '<head>'
cMsg += '	<title>CIEE</title>'
cMsg += '</head>'
cMsg += '<body>'
cMsg += '	<form name="form1" method="post" action="mailto:%WFMailTo%">'
cMsg += '		<table width="100%" height="23" border="0" vspace="0" hspace="0" cellspacing="0" cellpadding="0">'
cMsg += '			<tr>'
cMsg += '					<td bgcolor="#FFFFFF" rowspan="2" style="font-size: 8pt">'
cMsg += '						<p align="left">'
cMsg += '		                	<img src="' + cLinkLogo + '"width="183" height="80">'
cMsg += '						</p>'
cMsg += '					</td>'
cMsg += '					<td width="100%" bgcolor="#014282" style="font-size: 8pt" height="20">'
cMsg += '						<p align="center">'
cMsg += '							<font face="Arial" size="4" color="#FFFFFF">'
cMsg += '								<span style="background-color: #014282">Novas unidades CIEE cadastradas na ZCN</span>'
cMsg += '							</font>'
cMsg += '						</p>'
cMsg += '					</td>'
cMsg += '				</tr>'
cMsg += '			</table>'
cMsg += '			<font size="4">'
cMsg += '				<p>'
cMsg += '					<font face="Arial">'
cMsg += '						<p>'
cMsg += '							<font face="Arial">'
cMsg += '								<span lang="pt-br">'
cMsg += '									<font size="4">Abaixo relação das unidades cadastradas na tabela ZCN.</font>'
cMsg += '								</span>'
cMsg += '							</font>'
cMsg += '						</p>'
cMsg += '						<p>'
cMsg += '							<table style="width:100%" border="1">'
cMsg += '								<tr>'
cMsg += '									<th>Código</th>'
cMsg += '									<th>CNPJ</th>'
cMsg += '									<th>Descrição</th>'
cMsg += '								</tr>'
cMsg += cItens
cMsg += '							</table>'
cMsg += '						</p>'
cMsg += '					</font>'
cMsg += '				</p>'
cMsg += '				<p>'
cMsg += '					<font face="Arial" size="4">Favor não responder este e-mail.</font>'
cMsg += '				</p>'
cMsg += '			</font>'
cMsg += '		</form>'
cMsg += '	</body>'
cMsg += '</html>'

oMessage := TMailMessage():New()
oMessage:Clear()
oMessage:cFrom    := ALLTRIM(WF7->WF7_ENDERE)
oMessage:cTo      := "danilo.grodzicki@totvs.com.br"  // Alltrim(GetMv("CI_GRPFIN",.F.,"felipe.queiroz@ciee.ong.br"))
oMessage:cBody    := cMsg
oMessage:cSubject := "Novas unidades CIEE cadastradas na ZCN"

nErro := oMessage:Send( oMail )
If nErro <> 0
	oMail:SMTPDisconnect()
	U_uCONOUT("C6A95EMAIL - " + DtoC(Date()) + " - " + Time() + " - FALHA ENVIO EMAIL NOVA UNIDADE TABELA ZCN")
	Return(.F.)
Endif

oMail:SMTPDisconnect()

Return(.T.)