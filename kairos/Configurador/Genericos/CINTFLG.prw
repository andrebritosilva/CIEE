#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} CINTFLG
Classe de integração com FLUIG
@author carlos.henrique
@since 10/05/2019
@version undefined

@type class
/*/
Class CINTFLG
	DATA EcmUrl
	DATA Login
	DATA Password
	DATA CompanyId
	DATA UserId
	DATA Nome
	DATA CodCR
	DATA DesCR
	DATA attachments
	DATA IdDocs
	DATA IdSol
	DATA Error
	DATA lSslInsecure
	DATA Colleague
	Method New() CONSTRUCTOR
	Method setUserId(cUsrCod,lRH)
	Method setAnexo(cAlias)
	Method startprocess(cProcessId,nChoosedState,aColleagueIds,cComments,cUserId,lCompleteTask,attachments,aCardData,appointment,lManagerMode)
	Method cancelInstance(cProcessId,cUserId,cComments)
	Method getColleague(cUserId)
	Method createColleague(cUserId,cNome,cLgRede,cEmail)
	Method updateColleague(cUserId,cNome,cLgRede,cEmail)
	Method removeColleague(cUserId)
	Method activateColleague(cUserId)
End Class

/*/{Protheus.doc} New
Método construtor
@author carlos.henrique
@since 22/05/2019
@version undefined

@type function
/*/
Method New(lSetMV) Class CINTFLG
Default lSetMV  := .F.

IF lSetMV
	Self:EcmUrl		:= TRIM(SuperGetMv("MV_ECMURL" ,.F.,""))
	Self:Login		:= TRIM(SuperGetMv("MV_ECMPUBL",.F.,""))
	Self:Password	:= TRIM(SuperGetMv("MV_ECMPSW" ,.F.,""))
	Self:CompanyId	:= TRIM(SuperGetMv("MV_ECMEMP" ,.F.,""))
ENDIF

SELF:IdDocs	    := ""
Self:Error		:= ""
SELF:attachments:= {}
SELF:lSslInsecure	:= .T.

Return Self

/*/{Protheus.doc} setUserId
Seta matricula de acordo com a ZAA
@author carlos.henrique
@since 15/05/2019
@version undefined

@type function
/*/
Method setUserId(cUsrCod,lRH,cLgRede) Class CINTFLG
Local lRet	:= .F.
Local cTab  := ""
Local aMatSub	:= {}
Local aDadossub	:= {}
Default cUsrCod	:= RetCodUsr()
Default lRH  	:= .F.
default cLgRede	:= ""

if empty(cLgRede)
	cLgRede:= ALLTRIM(UsrRetName(cUsrCod))
endif

//Tratamento para ambiente do RH
IF lRH

	if trim(cLgRede) == "Siga"
		if CEMPANT=="40"
			lRet:= .T.
			SELF:UserId := "ciee"
			SELF:Nome   := "CIEE"
			SELF:CodCR  := "165"
			SELF:DesCR  := "DESENVOLVIMENTO DE SISTEMAS"
		elseif CEMPANT=="50"
			lRet:= .T.
			SELF:UserId := "cieerio"
			SELF:Nome   := "CIEE"
			SELF:CodCR  := "165"
			SELF:DesCR  := "DESENVOLVIMENTO DE SISTEMAS"
		endif
	else
		cTab:= GetNextAlias()
		BeginSql Alias cTab
			SELECT RA_MAT,RA_NOME,RA_CC,CTT_DESC01 FROM %TABLE:SRA% SRA
			INNER JOIN %TABLE:CTT% CTT ON CTT_FILIAL=%EXP:XFILIAL("CTT")%
				AND CTT_CUSTO=RA_CC
				AND CTT.D_E_L_E_T_=''
			WHERE LTRIM(RTRIM(RA_XLGREDE))=%EXP:cLgRede%
			AND SRA.D_E_L_E_T_=''
		EndSql

		//GETLastQuery()[2]

		(cTab)->(dbSelectArea((cTab)))
		(cTab)->(dbGoTop())
		IF (cTab)->(!EOF())
		   lRet:= .T.
		   SELF:UserId := CVALTOCHAR(VAL((cTab)->RA_MAT))
		   SELF:Nome   := ALLTRIM((cTab)->RA_NOME)
		   SELF:CodCR  := ALLTRIM((cTab)->RA_CC)
		   SELF:DesCR  := ALLTRIM((cTab)->CTT_DESC01)
		ELSE
		   SELF:Error:= "Usuário "+cLgRede+" sem login de rede informado no cadastro!"+CRLF+"Verique o campo ==> RA_XLGREDE"
		ENDIF
		(cTab)->(dbCloseArea())
	endif
ELSE
	cTab:= GetNextAlias()
	BeginSql Alias cTab
		SELECT ZAA_MAT,ZAA_NOME,ZAA_CC,CTD_DESC01 FROM %TABLE:ZAA% ZAA
		INNER JOIN %TABLE:CTD% CTD ON CTD_FILIAL=%EXP:XFILIAL("CTD")%
			AND CTD_ITEM=ZAA_CC
			AND CTD.D_E_L_E_T_=''
		WHERE (LTRIM(RTRIM(ZAA_LGREDE))=%EXP:cLgRede% OR RTRIM(ZAA_MAT)=%EXP:LEFT(cLgRede,5)%)
		AND ZAA.D_E_L_E_T_=''
	EndSql

	//GETLastQuery()[2]

	(cTab)->(dbSelectArea((cTab)))
	(cTab)->(dbGoTop())
	IF (cTab)->(!EOF())
	   lRet:= .T.
	   SELF:UserId 	:= ALLTRIM((cTab)->ZAA_MAT)
	   SELF:Nome  	:= ALLTRIM((cTab)->ZAA_NOME)
	   SELF:CodCR  	:= ALLTRIM((cTab)->ZAA_CC)
	   SELF:DesCR  	:= ALLTRIM((cTab)->CTD_DESC01)

	   //Tratamento de substituto igual a pré nota
	   IF LEN(aMatSub:=U_CCA10ZANSUB(SELF:UserId )) > 0

	   		SELF:UserId	:= aMatSub[aScan(aMatSub,{|x| AllTrim(x[1])=='ZAN_MATSUB'}), 2]

			IF LEN(aDadossub:= U_CCA10ZAASUB(SELF:UserId)) > 0
				SELF:Nome 	:= aDadossub[aScan(aDadossub,{|x| AllTrim(x[1])=='ZAA_NOME'}), 2]
				SELF:CodCR 	:= aDadossub[aScan(aDadossub,{|x| AllTrim(x[1])=='ZAA_CC'}), 2]
				SELF:DesCR  := ALLTRIM(POSICIONE("CTD",1,XFILIAL("CTD")+SELF:CodCR,"CTD_DESC01"))
			ENDIF

	   ENDIF
	ELSE
	   SELF:Error:= "Usuário "+cUsrCod+" sem login de rede informado no cadastro!"+CRLF+"Verique o cadastro da tabela ZAA"
	ENDIF
	(cTab)->(dbCloseArea())
ENDIF

Return lRet

/*/{Protheus.doc} setAnexo
Seta array de anexos do processo para upload no formulario
@author carlos.henrique
@since 15/05/2019
@version undefined

@type function
/*/
Method setAnexo(cAlias) Class CINTFLG
Local lRet:= .T.

//DBSELECTAREA("SX2")
//SX2->(DBSEEK(cAlias))
IF EMPTY(FwSX2Util():GetSX2data(cAlias, {"X2_DISPLAY"})[1][2])
	SELF:Error:= "Campo X2_DISPLAY não informado para tabela "+ cAlias
	Return .F.
ELSE
	SELF:IdDocs+=  U_CCFGE03(cAlias,(cAlias)->(RECNO()),,,,.T.)
ENDIF

Return lRet
/*/{Protheus.doc} startprocess
Inicia processo Fluig
@author carlos.henrique
@since 15/05/2019
@version undefined
@param cProcessId, characters, descricao
@param cChoosedState, characters, descricao
@param aColleagueIds, array, descricao
@param cComments, characters, descricao
@param cUserId, characters, descricao
@param lCompleteTask, logical, descricao
@param attachments, array, descricao
@param aCardData, array, descricao
@param appointment, array, descricao
@param lManagerMode, logical, descricao
@type function
/*/
Method startprocess(cProcessId,cChoosedState,aColleagueIds,cComments,cUserId,lCompleteTask,attachments,aCardData,appointment,lManagerMode) Class CINTFLG
Local oWsdl	  := TWsdlManager():New()
Local cXml	  := ""
Local cError  := ""
Local cWarning:= ""
Local nCnta   := 0
DEFAULT cProcessId		:= ""
DEFAULT cChoosedState	:= "0"
DEFAULT aColleagueIds	:= {}
DEFAULT cComments		:= ""
DEFAULT cUserId			:= ""
DEFAULT lCompleteTask	:= .F.
DEFAULT attachments  	:= {}
DEFAULT aCardData 	 	:= {}
DEFAULT appointment  	:= {}
DEFAULT lManagerMode 	:= .F.

oWsdl:lSSLInsecure := self:lSslInsecure

IF !oWsdl:ParseURL(Self:EcmUrl+"ECMWorkflowEngineService?wsdl")
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel realizar o parse do serviço.")
	Return .F.
ENDIF

aOper:= oWsdl:ListOperations()
IF (nOper := ASCAN(aOper,{|x| x[1]=="startProcess"})) == 0
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel setar a operação startProcess.")
	Return .F.
ENDIF

IF !oWsdl:SetOperation(aOper[nOper][1])
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel setar a operação startProcess.")
	Return .F.
ENDIF

oWsdl:cLocation:= Self:EcmUrl + "ECMWorkflowEngineService"

cXml+= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.workflow.ecm.technology.totvs.com/">'
cXml+= '	<soapenv:Header/>'
cXml+= '	<soapenv:Body>'
cXml+= '		<ws:startProcess>'
cXml+= '			<username>'+SELF:Login+'</username>'
cXml+= '			<password>'+SELF:Password+'</password>'
cXml+= '			<companyId>'+SELF:CompanyId+'</companyId>'
cXml+= '			<processId>'+cProcessId+'</processId>'
cXml+= '			<choosedState>'+cChoosedState+'</choosedState>'
cXml+= '			<colleagueIds><item>System:Auto</item></colleagueIds>'
cXml+= '			<comments>'+cComments+'</comments>'
cXml+= '			<userId>'+cUserId+'</userId>'
cXml+= '			<completeTask>'+IIF(lCompleteTask,"true","false")+'</completeTask>'

IF !EMPTY(attachments)
	cXml+= '			<attachments>

	For nCnta:= 1 to Len(attachments)

		cXml+= '				<item>'
		cXml+= '					<attachmentSequence>'+CVALTOCHAR(nCnta)+'</attachmentSequence>'
		cXml+= '					<attachments>'
		cXml+= '						<attach>true</attach>'
		cXml+= '						<editing>true</editing>'
		cXml+= '						<fileName>'+attachments[nCnta][1]+'</fileName>'
		cXml+= '						<filecontent>'+ Encode64(,attachments[nCnta][2],.F.,.F.) +'</filecontent>'
		cXml+= '						<fileSize>0</fileSize>'
		cXml+= '						<principal>true</principal>'
		cXml+= '						<mobile>true</mobile>'
		cXml+= '					</attachments>'
		cXml+= '					<description>'+attachments[nCnta][1]+'</description>'
		cXml+= '					<fileName>'+attachments[nCnta][1]+'</fileName>'
		cXml+= '				</item>'

	Next

	cXml+= '			</attachments>
ELSE
	cXml+= '			<attachments></attachments>'
ENDIF

cXml+= '			<cardData>'

For nCnta:= 1 to Len(aCardData)
	cXml += '				<item><item>'+aCardData[nCnta][1]+'</item><item>'+aCardData[nCnta][2]+'</item></item>'
Next

cXml+= '			</cardData>'
cXml+= '			<appointment></appointment>'
cXml+= '			<managerMode>'+IIF(lManagerMode,"true","false")+'</managerMode>'
cXml+= '		</ws:startProcess>'
cXml+= '	</soapenv:Body>'
cXml+= '</soapenv:Envelope>'

oWsdl:cEncoding := "UTF-8"

oWsdl:SendSoapMsg(ENCODEUTF8(cXml))

oRet:= XmlParser(oWsdl:GetSoapResponse(),"_",@cError,@cWarning)

IF !EMPTY(cError)
	SELF:Error:= "Erro: " + cError
	Return .F.
ELSE
	IF TYPE("oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_STARTPROCESSRESPONSE:_RESULT:_ITEM[6]:_ITEM[2]:TEXT") == "C"
		SELF:IdSol:= oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_STARTPROCESSRESPONSE:_RESULT:_ITEM[6]:_ITEM[2]:TEXT
	ELSE
		SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel iniciar o processo no fluig.")
		Return .F.
	ENDIF
ENDIF

FreeObj(oWsdl)
FreeObj(oRet)


Return .T.
/*/{Protheus.doc} cancelInstance
Método de cancelamento de solicitação no fluig
@author carlos.henrique
@since 13/09/2019
@version undefined
@param cProcessId, characters, descricao
@param cUserId, characters, descricao
@param cComments, characters, descricao
@type function
/*/
Method cancelInstance(cProcessId,cUserId,cComments) Class CINTFLG
Local oWsdl	  := TWsdlManager():New()
Local cXml	  := ""
//Local cError  := ""
//Local cWarning:= ""
DEFAULT cProcessId		:= ""
DEFAULT cUserId			:= ""
DEFAULT cComments		:= ""

IF !oWsdl:ParseURL(Self:EcmUrl+"ECMWorkflowEngineService?wsdl")
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel realizar o parse do serviço.")
	Return .F.
ENDIF

aOper:= oWsdl:ListOperations()
IF (nOper := ASCAN(aOper,{|x| x[1]=="cancelInstance"})) == 0
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel setar a operação cancelInstance.")
	Return .F.
ENDIF

IF !oWsdl:SetOperation(aOper[nOper][1])
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel setar a operação cancelInstance.")
	Return .F.
ENDIF

oWsdl:cLocation:= Self:EcmUrl + "ECMWorkflowEngineService"

cXml+= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.workflow.ecm.technology.totvs.com/">'
cXml+= '	<soapenv:Header/>'
cXml+= '	<soapenv:Body>'
cXml+= '		<ws:cancelInstance>'
cXml+= '			<username>'+SELF:Login+'</username>'
cXml+= '			<password>'+SELF:Password+'</password>'
cXml+= '			<companyId>'+SELF:CompanyId+'</companyId>'
cXml+= '			<processInstanceId>'+cProcessId+'</processInstanceId>'
cXml+= '			<userId>'+cUserId+'</userId>'
cXml+= '			<cancelText>'+cComments+'</cancelText>'
cXml+= '		</ws:cancelInstance>'
cXml+= '	</soapenv:Body>'
cXml+= '</soapenv:Envelope>'

oWsdl:cEncoding := "UTF-8"

oWsdl:SendSoapMsg(ENCODEUTF8(cXml))

IF !EMPTY(oWsdl:cError)
	SELF:Error:= "Erro: " + oWsdl:cError
	Return .F.
ENDIF

FreeObj(oWsdl)
FreeObj(oRet)

Return .T.

/*/{Protheus.doc} getColleague
Método de consulta de usuário no Fluig
@author carlos.henrique
@since 13/09/2019
@version undefined
@param cUserId, characters, descricao
@type function
/*/
Method getColleague(cUserId) Class CINTFLG
Local oWsdl	  := TWsdlManager():New()
Local cXml	  := ""
Local cError  := ""
Local cWarning:= ""
DEFAULT cUserId		:= ""

oWsdl:lSSLInsecure := self:lSslInsecure

IF !oWsdl:ParseURL(Self:EcmUrl+"ECMColleagueService?wsdl")
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel realizar o parse do serviço.")
	FreeObj(oWsdl)
	Return .F.
ENDIF

aOper:= oWsdl:ListOperations()
IF (nOper := ASCAN(aOper,{|x| x[1]=="getColleague"})) == 0
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel setar a operação getColleague.")
	FreeObj(oWsdl)
	Return .F.
ENDIF

IF !oWsdl:SetOperation(aOper[nOper][1])
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel setar a operação getColleague.")
	FreeObj(oWsdl)
	Return .F.
ENDIF

oWsdl:cLocation:= Self:EcmUrl + "ECMColleagueService"

cXml+= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.foundation.ecm.technology.totvs.com/">'
cXml+= '   <soapenv:Header/>'
cXml+= '   <soapenv:Body>'
cXml+= '      <ws:getColleague>'
cXml+= '		<username>'+SELF:Login+'</username>'
cXml+= '		<password>'+SELF:Password+'</password>'
cXml+= '		<companyId>'+SELF:CompanyId+'</companyId>'
cXml+= '        <colleagueId>'+cUserId+'</colleagueId>'
cXml+= '      </ws:getColleague>'
cXml+= '   </soapenv:Body>'
cXml+= '</soapenv:Envelope>'

oWsdl:cEncoding := "UTF-8"

oWsdl:SendSoapMsg(ENCODEUTF8(cXml))

IF !EMPTY(oWsdl:cError)
	SELF:Error:= "Erro: " + oWsdl:cError
	FreeObj(oWsdl)
	Return .F.
ENDIF

oRet:= XmlParser(oWsdl:GetSoapResponse(),"_",@cError,@cWarning)

IF !EMPTY(cError)
	SELF:Error:= "Erro: " + cError
	FreeObj(oWsdl)
	Return .F.
endif

if TYPE("oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_GETCOLLEAGUERESPONSE:_COLAB:_ITEM") != "U"
	IF oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_GETCOLLEAGUERESPONSE:_COLAB:_ITEM:_COMPANYID:TEXT=="0"
		SELF:Error:= "Login: Matricula não cadastrada."
		FreeObj(oWsdl)
		Return .F.
	ELSE
		SELF:Colleague:= oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_GETCOLLEAGUERESPONSE:_COLAB:_ITEM
	ENDIF
endif

FreeObj(oWsdl)

Return .T.

/*/{Protheus.doc} createColleague
Método de inclusão de usuário no Fluig
@author carlos.henrique
@since 13/09/2019
@version undefined
@param cUserId, characters, descricao
@param cNome, characters, descricao
@param cEmail, characters, descricao
@type function
/*/
Method createColleague(cUserId,cNome,cLgRede,cEmail) Class CINTFLG
Local oWsdl	  := TWsdlManager():New()
Local cXml	  := ""
Local cError  := ""
Local cWarning:= ""

oWsdl:lSSLInsecure := self:lSslInsecure

IF !oWsdl:ParseURL(Self:EcmUrl+"ECMColleagueService?wsdl")
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel realizar o parse do serviço.")
	FreeObj(oWsdl)
	Return .F.
ENDIF

aOper:= oWsdl:ListOperations()
IF (nOper := ASCAN(aOper,{|x| x[1]=="createColleague"})) == 0
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel setar a operação createColleague.")
	FreeObj(oWsdl)
	Return .F.
ENDIF

IF !oWsdl:SetOperation(aOper[nOper][1])
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel setar a operação createColleague.")
	FreeObj(oWsdl)
	Return .F.
ENDIF

oWsdl:cLocation:= Self:EcmUrl + "ECMColleagueService"

cXml+= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.foundation.ecm.technology.totvs.com/">'
cXml+= '   <soapenv:Header/>'
cXml+= '   <soapenv:Body>'
cXml+= '      <ws:createColleague>'
cXml+= '		<username>'+SELF:Login+'</username>'
cXml+= '		<password>'+SELF:Password+'</password>'
cXml+= '		<companyId>'+SELF:CompanyId+'</companyId>'
cXml+= '        <colleagues>'
cXml+= '           <item>'
cXml+= '			  <active>true</active>'
cXml+= '			  <colleagueId>'+cUserId+'</colleagueId>'
cXml+= '			  <colleagueName>'+cNome+'</colleagueName>'
cXml+= '			  <companyId>'+SELF:CompanyId+'</companyId>'
cXml+= '			  <login>'+cLgRede+'</login>'
cXml+= '			  <mail>'+cEmail+'</mail>'
cXml+= '			  <passwd>'+cLgRede+'</passwd>'
cXml+= '           </item>'
cXml+= '       </colleagues>'
cXml+= '      </ws:createColleague>'
cXml+= '   </soapenv:Body>'
cXml+= '</soapenv:Envelope>'

oWsdl:cEncoding := "UTF-8"

oWsdl:SendSoapMsg(ENCODEUTF8(cXml))

IF !EMPTY(oWsdl:cError)
	SELF:Error:= "Erro: " + oWsdl:cError
	FreeObj(oWsdl)
	Return .F.
ENDIF

oRet:= XmlParser(oWsdl:GetSoapResponse(),"_",@cError,@cWarning)

IF !EMPTY(cError)
	SELF:Error:= "Erro: " + cError
	FreeObj(oWsdl)
	Return .F.
endif

if TYPE("oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_CREATECOLLEAGUERESPONSE:_RESULTXML:TEXT") != "U"
	IF UPPER(LEFT(oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_CREATECOLLEAGUERESPONSE:_RESULTXML:TEXT,3))=="NOK"
		SELF:Error:= "Erro: " + oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_CREATECOLLEAGUERESPONSE:_RESULTXML:TEXT
		IF "JÁ CADASTRADO"$UPPER(SELF:Error)
			SELF:Error:= ""
		ELSE
			FreeObj(oWsdl)
			Return .F.
		ENDIF
	ENDIF
endif

FreeObj(oWsdl)
Return .T.

/*/{Protheus.doc} updateColleague
Método de atualização de usuário no Fluig
@author carlos.henrique
@since 13/09/2019
@version undefined
@param cUserId, characters, descricao
@param cNome, characters, descricao
@param cEmail, characters, descricao
@type function
/*/
Method updateColleague(cUserId,cNome,cLgRede,cEmail) Class CINTFLG
Local oWsdl	  := nil
Local cXml	  := ""
Local cError  := ""
Local cWarning:= ""

IF SELF:getColleague(cUserId)

	//Ativa uauário
	if SELF:Colleague:_ACTIVE:TEXT == "false"
		IF !SELF:activateColleague(cUserId)
			FreeObj(oWsdl)
			Return .F.
		endif
	endif

	//Seta parametros de atualização
	SELF:Colleague:_COLLEAGUEID:TEXT	:= cUserId
	SELF:Colleague:_COLLEAGUENAME:TEXT	:= cNome
	SELF:Colleague:_LOGIN:TEXT			:= cLgRede
	SELF:Colleague:_MAIL:TEXT			:= cEmail


	oWsdl:= TWsdlManager():New()

	oWsdl:lSSLInsecure := self:lSslInsecure

	IF !oWsdl:ParseURL(Self:EcmUrl+"ECMColleagueService?wsdl")
		SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel realizar o parse do serviço.")
		FreeObj(oWsdl)
		Return .F.
	ENDIF

	aOper:= oWsdl:ListOperations()
	IF (nOper := ASCAN(aOper,{|x| x[1]=="updateColleague"})) == 0
		SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel setar a operação updateColleague.")
		FreeObj(oWsdl)
		Return .F.
	ENDIF

	IF !oWsdl:SetOperation(aOper[nOper][1])
		SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel setar a operação updateColleague.")
		FreeObj(oWsdl)
		Return .F.
	ENDIF

	oWsdl:cLocation:= Self:EcmUrl + "ECMColleagueService"

	cXml+= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.foundation.ecm.technology.totvs.com/">'
	cXml+= '   <soapenv:Header/>'
	cXml+= '   <soapenv:Body>'
	cXml+= '      <ws:updateColleague>'
	cXml+= '		<username>'+SELF:Login+'</username>'
	cXml+= '		<password>'+SELF:Password+'</password>'
	cXml+= '		<companyId>'+SELF:CompanyId+'</companyId>'
	cXml+= '        <colleagues>'
	cXml+= '           <item>'
	cXml+= '			  <active>true</active>'
	cXml+= '			  <adminUser>'+SELF:Colleague:_ADMINUSER:TEXT+'</adminUser>'
	cXml+= '			  <colleagueId>'+SELF:Colleague:_COLLEAGUEID:TEXT+'</colleagueId>'
	cXml+= '			  <colleagueName>'+SELF:Colleague:_COLLEAGUENAME:TEXT+'</colleagueName>'
	cXml+= '			  <companyId>'+SELF:Colleague:_COMPANYID:TEXT+'</companyId>'
	cXml+= '			  <currentProject/>'
	cXml+= '			  <defaultLanguage>'+SELF:Colleague:_DEFAULTLANGUAGE:TEXT+'</defaultLanguage>'
	cXml+= '			  <dialectId>'+SELF:Colleague:_DIALECTID:TEXT+'</dialectId>'
	cXml+= '			  <ecmVersion>'+SELF:Colleague:_ECMVERSION:TEXT+'</ecmVersion>'
	cXml+= '			  <emailHtml>'+SELF:Colleague:_EMAILHTML:TEXT+'</emailHtml>'
	cXml+= '			  <gedUser>'+SELF:Colleague:_GEDUSER:TEXT+'</gedUser>'
	cXml+= '			  <groupId/>'
	cXml+= '			  <login>'+SELF:Colleague:_LOGIN:TEXT+'</login>'
	cXml+= '			  <mail>'+SELF:Colleague:_MAIL:TEXT+'</mail>'
	cXml+= '			  <menuConfig>'+SELF:Colleague:_MENUCONFIG:TEXT+'</menuConfig>'
	cXml+= '			  <passwd/>'
	cXml+= '			  <rowId>'+SELF:Colleague:_ROWID:TEXT+'</rowId>'
	cXml+= '			  <usedSpace>'+SELF:Colleague:_USEDSPACE:TEXT+'</usedSpace>'
	cXml+= '           </item>'
	cXml+= '       </colleagues>'
	cXml+= '      </ws:updateColleague>'
	cXml+= '   </soapenv:Body>'
	cXml+= '</soapenv:Envelope>'

	oWsdl:cEncoding := "UTF-8"

	oWsdl:SendSoapMsg(ENCODEUTF8(cXml))

	IF !EMPTY(oWsdl:cError)
		SELF:Error:= "Erro: " + oWsdl:cError
		FreeObj(oWsdl)
		Return .F.
	ENDIF

	oRet:= XmlParser(oWsdl:GetSoapResponse(),"_",@cError,@cWarning)

	IF !EMPTY(cError)
		SELF:Error:= "Erro: " + cError
		FreeObj(oWsdl)
		Return .F.
	endif

	if TYPE("oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_UPDATECOLLEAGUERESPONSE:_RESULTXML:TEXT") != "U"
		IF UPPER(LEFT(oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_UPDATECOLLEAGUERESPONSE:_RESULTXML:TEXT,3))=="NOK"
			SELF:Error:= "Erro: " + oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_UPDATECOLLEAGUERESPONSE:_RESULTXML:TEXT
			FreeObj(oWsdl)
			Return .F.
		ENDIF
	endif

	FreeObj(oWsdl)
ELSE
	Return .F.
ENDIF

Return .T.
/*/{Protheus.doc} removeColleague
Método de exclusão de usuário no Fluig
@author carlos.henrique
@since 13/09/2019
@version undefined
@param cUserId, characters, descricao
@type function
/*/
Method removeColleague(cUserId) Class CINTFLG
Local oWsdl	  := TWsdlManager():New()
Local cXml	  := ""
Local cError  := ""
Local cWarning:= ""
DEFAULT cUserId		:= ""

oWsdl:lSSLInsecure := self:lSslInsecure

IF !oWsdl:ParseURL(Self:EcmUrl+"ECMColleagueService?wsdl")
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel realizar o parse do serviço.")
	FreeObj(oWsdl)
	Return .F.
ENDIF

aOper:= oWsdl:ListOperations()
IF (nOper := ASCAN(aOper,{|x| x[1]=="removeColleague"})) == 0
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel setar a operação removeColleague.")
	FreeObj(oWsdl)
	Return .F.
ENDIF

IF !oWsdl:SetOperation(aOper[nOper][1])
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel setar a operação removeColleague.")
	FreeObj(oWsdl)
	Return .F.
ENDIF

oWsdl:cLocation:= Self:EcmUrl + "ECMColleagueService"

cXml+= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.foundation.ecm.technology.totvs.com/">'
cXml+= '   <soapenv:Header/>'
cXml+= '   <soapenv:Body>'
cXml+= '      <ws:removeColleague>'
cXml+= '		<username>'+SELF:Login+'</username>'
cXml+= '		<password>'+SELF:Password+'</password>'
cXml+= '		<companyId>'+SELF:CompanyId+'</companyId>'
cXml+= '        <colleagueId>'+cUserId+'</colleagueId>'
cXml+= '      </ws:removeColleague>'
cXml+= '   </soapenv:Body>'
cXml+= '</soapenv:Envelope>'

oWsdl:cEncoding := "UTF-8"

oWsdl:SendSoapMsg(ENCODEUTF8(cXml))

IF !EMPTY(oWsdl:cError)
	SELF:Error:= "Erro: " + oWsdl:cError
	FreeObj(oWsdl)
	Return .F.
ENDIF

oRet:= XmlParser(oWsdl:GetSoapResponse(),"_",@cError,@cWarning)

IF !EMPTY(cError)
	SELF:Error:= "Erro: " + cError
	FreeObj(oWsdl)
	Return .F.
endif

if TYPE("oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_REMOVECOLLEAGUERESPONSE:_RESULT:TEXT") != "U"
	IF UPPER(LEFT(oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_REMOVECOLLEAGUERESPONSE:_RESULT:TEXT,3))=="NOK"
		SELF:Error:= "Erro: " + oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_REMOVECOLLEAGUERESPONSE:_RESULT:TEXT
		FreeObj(oWsdl)
		Return .F.
	ENDIF
endif

FreeObj(oWsdl)

Return .T.
/*/{Protheus.doc} activateColleague
Método de ativação de usuário no Fluig
@author carlos.henrique
@since 13/09/2019
@version undefined
@param cUserId, characters, descricao
@type function
/*/
Method activateColleague(cUserId) Class CINTFLG
Local oWsdl	  := TWsdlManager():New()
Local cXml	  := ""
Local cError  := ""
Local cWarning:= ""
DEFAULT cUserId		:= ""

oWsdl:lSSLInsecure := self:lSslInsecure

IF !oWsdl:ParseURL(Self:EcmUrl+"ECMColleagueService?wsdl")
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel realizar o parse do serviço.")
	FreeObj(oWsdl)
	Return .F.
ENDIF

aOper:= oWsdl:ListOperations()
IF (nOper := ASCAN(aOper,{|x| x[1]=="activateColleague"})) == 0
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel setar a operação activateColleague.")
	FreeObj(oWsdl)
	Return .F.
ENDIF

IF !oWsdl:SetOperation(aOper[nOper][1])
	SELF:Error:= If(!Empty(oWsdl:cError),oWsdl:cError, "Não foi possivel setar a operação activateColleague.")
	FreeObj(oWsdl)
	Return .F.
ENDIF

oWsdl:cLocation:= Self:EcmUrl + "ECMColleagueService"

cXml+= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.foundation.ecm.technology.totvs.com/">'
cXml+= '   <soapenv:Header/>'
cXml+= '   <soapenv:Body>'
cXml+= '      <ws:activateColleague>'
cXml+= '		<username>'+SELF:Login+'</username>'
cXml+= '		<password>'+SELF:Password+'</password>'
cXml+= '		<companyId>'+SELF:CompanyId+'</companyId>'
cXml+= '        <colleagueId>'+cUserId+'</colleagueId>'
cXml+= '      </ws:activateColleague>'
cXml+= '   </soapenv:Body>'
cXml+= '</soapenv:Envelope>'

oWsdl:cEncoding := "UTF-8"

oWsdl:SendSoapMsg(ENCODEUTF8(cXml))

IF !EMPTY(oWsdl:cError)
	SELF:Error:= "Erro: " + oWsdl:cError
	FreeObj(oWsdl)
	Return .F.
ENDIF

oRet:= XmlParser(oWsdl:GetSoapResponse(),"_",@cError,@cWarning)

IF !EMPTY(cError)
	SELF:Error:= "Erro: " + cError
	FreeObj(oWsdl)
	Return .F.
endif

if TYPE("oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_ACTIVATECOLLEAGUERESPONSE:_RESULT:TEXT") != "U"
	IF UPPER(LEFT(oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_ACTIVATECOLLEAGUERESPONSE:_RESULT:TEXT,3))=="NOK"
		SELF:Error:= "Erro: " + oRet:_SOAP_ENVELOPE:_SOAP_BODY:_NS1_ACTIVATECOLLEAGUERESPONSE:_RESULT:TEXT
		FreeObj(oWsdl)
		Return .F.
	ENDIF
endif

FreeObj(oWsdl)

Return .T.