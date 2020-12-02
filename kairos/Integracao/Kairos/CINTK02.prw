#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

/*/{Protheus.doc} CINTK02
Servi�o de integra��o das configura��es de Cobran�a
@author carlos.henrique
@since 19/03/2019
@version undefined
@type function
/*/
USER FUNCTION CINTK02(nRecno) 

Local cErro
Local cMsgOK := ""

Private oRet       := Nil
Private oJson      := Nil
Private cJson      := Nil
Private cUteis     := space(001)
Private cEmiNf     := space(001)
Private cSerasa    := space(001)
Private cConfPa    := space(001)
Private cEnvBco    := space(001)
Private cEnvBol    := space(001)
Private cTipVen    := space(001)
Private cRegVen    := space(001)
Private cDiaSem    := space(002)
Private cRegFer    := space(001)
Private cSemUte    := space(002)
Private cSemCon    := space(001)
Private cEmiRec    := space(001)
Private cVlrTot    := space(001)
Private cRecAut    := space(001)
Private cCarFat    := space(001)
Private cUniLoc    := space(001)
Private cVtotnf    := space(001)
Private cCobTer    := space(001)
Private cRepEmp    := space(001)
Private cCisepa    := space(001)
Private cSigla     := space(002)
Private cVldFat    := space(001)
Private cIdConf    := space(015)
Private cIdCont    := space(015)
Private cIdPgto    := space(015)
Private cNomcob    := space(150)
Private cNomctr    := space(150)
Private cCpfctr    := space(011)
Private cDddctr    := space(002)
Private cTelctr    := space(009)
Private cRamctr    := space(009)
Private cMailct    := space(100)
Private cCarctr    := space(100)
Private cMaibol    := space(100)
Private cCodbco    := space(003)
Private cAgenci    := space(005)
Private cCtacre    := space(010)
Private cDtpave    := space(020)
Private cDiaven    := space(002)
Private cQtdias    := space(002)
Private cCep       := space(008)
Private cLograd    := space(150)
Private cCndere    := space(150)
Private cNumero    := space(010)
Private cComple    := space(050)
Private cBairro    := space(050)
Private cCoibge    := space(050)
Private cCidade    := space(050)
Private cEstado    := space(002)
Private cMsg       := space(150)
Private cBcocon    := space(003)
Private cAgeout    := space(005)
Private cCtacon    := space(010)
Private cObsrec    := space(150)
Private cObscar    := space(150)
Private cObsnf     := space(150)
Private cMailnf    := space(100)
Private cQtddia    := space(002)
Private cDiater    := space(002)
Private cLocvin    := space(015)
Private cUnresp    := space(015)
Private cDocres    := space(014)
Private cAreaSe    := space(100)
Private lErroTenta := .F.
Private cCarBco    := space(003)
Private cCarAge    := space(005)
Private cCarCc     := space(010)
Private cCarDcc    := space(002)

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK02] INICIO - Servi�o de integra��o das configura��es de Cobran�a - RECNO:" + CVALTOCHAR(nRecno))

DbSelectArea("CC2")
CC2->(DbSetOrder(01))

DbSelectArea("ZC3")
ZC3->(DbSetOrder(01))

DbSelectArea("ZCI")
ZCI->(DbSetOrder(01))

DbSelectarea("ZCN")
ZCN->(DbSetOrder(01))

DbSelectarea("ZCQ")
ZCQ->(DBGOTO(nRecno))

IF !EMPTY(ZCQ->ZCQ_JSON)

	oJson:= JsonObject():new()
	oJson:fromJson(ZCQ->ZCQ_JSON)   

	cJson := ZCQ->ZCQ_JSON

	// if  At("CONFIGURACAO",cJson) == 0
	// 	RECLOCK("ZCQ",.F.)
	// 		ZCQ->ZCQ_STATUS := "1" 	
	// 		ZCQ->ZCQ_CODE   := "404"  // Erro
	// 		ZCQ->ZCQ_MSG    := "Payload inv�lido"
	// 	MSUNLOCK()	
	// 	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"[CINTK02] FIM - Servi�o de integra��o das configura��es de Cobran�a - RECNO:" + CVALTOCHAR(nRecno))
	// 	Return
	// endif

	//Avalia o campo opera��o ZCQ_OPEENV - 1=POST;2=PUT;3=DELETE  
	Do CASE

		CASE	ZCQ->ZCQ_OPEENV == '1' 	//Antigo WSMETHOD POST 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"I")
			if Empty(cErro)
				GravaZc3(oJson)
				cMsgOK := "Configura��es de Cobran�a cadastrada com sucesso."
			endif

		CASE	ZCQ->ZCQ_OPEENV == '2'	//Antigo WSMETHOD PUT 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"A")
			if Empty(cErro)
				// Realiza a altera��o do contrato e local de contrato
				GravaZc3(oJson)
				cMsgOK := "Configura��es de Cobran�a alteradas com sucesso."
			endif

		CASE	ZCQ->ZCQ_OPEENV == '3'	//Antigo WSMETHOD DELETE 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"E")

			if Empty(cErro)

				// Destiva o registro na tabela ZC3
				Begin Transaction

					RecLock("ZC3",.F.)
						ZC3->ZC3_STATUS:= "2"
					ZC3->(MsUnLock())

				End Transaction

				cMsgOK := "Configura��es de Cobran�a desativada com sucesso."

			endif
	
	ENDCASE

	FreeObj(oJson)	 
ELSE
	cErro := "JSON N�O INFORMADO"
ENDIF

RECLOCK("ZCQ",.F.)

	if !Empty(cErro)
		if lErroTenta
			ZCQ->ZCQ_QTDTEN := ZCQ->ZCQ_QTDTEN + 1
			if ZCQ->ZCQ_QTDTEN <= GetMv("CI_QTDTENT")
				// Reprocessar o registro
				ZCQ->ZCQ_STATUS := "0" 	
				ZCQ->ZCQ_CODE   := "200"
			else
				ZCQ->ZCQ_STATUS := "1" 	
				ZCQ->ZCQ_CODE   := "404"  // Erro
				ZCQ->ZCQ_MSG    := cErro
			endif
		else
			ZCQ->ZCQ_STATUS := "1" 	
			ZCQ->ZCQ_CODE   := "404"  // Erro
			ZCQ->ZCQ_MSG    := cErro
		endif
	else
		ZCQ->ZCQ_STATUS := "2" 	
		ZCQ->ZCQ_CODE   := "200" // Sucesso
		ZCQ->ZCQ_MSG    := cMsgOK
		ZCQ->ZCQ_QTDTEN := 0
	endif
	
MSUNLOCK()	

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"[CINTK02] FIM - Servi�o de integra��o das configura��es de Cobran�a - RECNO:" + CVALTOCHAR(nRecno))

return


/*/{Protheus.doc} CONFIGCOB
Servi�o de integra��o das configura��es de Cobran�a
@author carlos.henrique
@since 01/03/2019
@version undefined
@type class
/*/
WSRESTFUL CONFIGCOB DESCRIPTION "Servi�o de integra��o das configura��es de cobran�a" FORMAT APPLICATION_JSON
	WSMETHOD POST; 
	DESCRIPTION "Realiza o cadastro das configura��es de cobran�a";
	WSSYNTAX "/CONFIGCOB"
	WSMETHOD PUT; 
	DESCRIPTION "Realiza a atualiza��o das configura��es de cobran�a";
	WSSYNTAX "/CONFIGCOB"
	WSMETHOD DELETE; 
	DESCRIPTION "Desativa as configura��es de cobran�a";
	WSSYNTAX "/CONFIGCOB"
	WSMETHOD GET; 
	DESCRIPTION "Realiza a consulta das configura��es de cobran�a";
	WSSYNTAX "/CONFIGCOB"
END WSRESTFUL
 
/*/{Protheus.doc} POST
Realiza o cadastro das configura��es de Faturamento
@author carlos.henrique
@since 01/03/2019
@version undefined

@type function
/*/
WSMETHOD POST WSSERVICE CONFIGCOB

Local cErro

Local aRet := {}

Private oRet      := Nil
Private oJson     := Nil
Private cJson     := Nil
Private cUteis    := space(001)
Private cEmiNf    := space(001)
Private cSerasa   := space(001)
Private cConfPa   := space(001)
Private cEnvBco   := space(001)
Private cEnvBol   := space(001)
Private cTipVen   := space(001)
Private cRegVen   := space(001)
Private cDiaSem   := space(002)
Private cRegFer   := space(001)
Private cSemUte   := space(002)
Private cSemCon   := space(001)
Private cEmiRec   := space(001)
Private cVlrTot   := space(001)
Private cRecAut   := space(001)
Private cCarFat   := space(001)
Private cUniLoc   := space(001)
Private cVtotnf   := space(001)
Private cCobTer   := space(001)
Private cRepEmp   := space(001)
Private cCisepa   := space(001)
Private cSigla    := space(002)
Private cVldFat   := space(001)
Private cIdConf   := space(015)
Private cIdCont   := space(015)
Private cIdPgto   := space(015)
Private cNomcob   := space(150)
Private cNomctr   := space(150)
Private cCpfctr   := space(011)
Private cDddctr   := space(002)
Private cTelctr   := space(009)
Private cRamctr   := space(009)
Private cMailct   := space(100)
Private cCarctr   := space(100)
Private cMaibol   := space(100)
Private cCodbco   := space(003)
Private cAgenci   := space(005)
Private cCtacre   := space(010)
Private cDtpave   := space(020)
Private cDiaven   := space(002)
Private cQtdias   := space(002)
Private cCep      := space(008)
Private cLograd   := space(150)
Private cCndere   := space(150)
Private cNumero   := space(010)
Private cComple   := space(050)
Private cBairro   := space(050)
Private cCoibge   := space(050)
Private cCidade   := space(050)
Private cEstado   := space(002)
Private cMsg      := space(150)
Private cBcocon   := space(003)
Private cAgeout   := space(005)
Private cCtacon   := space(010)
Private cObsrec   := space(150)
Private cObscar   := space(150)
Private cObsnf    := space(150)
Private cMailnf   := space(100)
Private cQtddia   := space(002)
Private cDiater   := space(002)
Private cLocvin   := space(015)
Private cUnresp   := space(015)
Private cDocres   := space(014)
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""
Private cAreaSe   := space(100)
Private cCarBco   := space(003)
Private cCarAge   := space(005)
Private cCarCc    := space(010)
Private cCarDcc   := space(002)

DbSelectArea("CC2")
CC2->(DbSetOrder(01))

DbSelectArea("ZC3")
ZC3->(DbSetOrder(01))

DbSelectArea("ZCI")
ZCI->(DbSetOrder(01))

DbSelectarea("ZCN")
ZCN->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"I")
if !Empty(cErro)
	U_GrvLogKa("CINTK02", "POST", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

//Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("CONFIGCOB",oJson:toJSON(),"POST")
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK02", "DW3POST", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

// Realiza a grava��o na tabela ZC3
GravaZc3(oJson)

U_GrvLogKa("CINTK02", "POST", "1", "Integracao realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Integracao realizada com sucesso")

/*/{Protheus.doc} PUT
Realiza a atualizacao das configura��es de Cobran�a
@author carlos.henrique
@since 01/03/2019
@version undefined

@type function
/*/
WSMETHOD PUT WSSERVICE CONFIGCOB

Local cErro

Local aRet := {}

Private oRet      := Nil
Private oJson     := Nil
Private cJson     := Nil
Private cUteis    := space(001)
Private cEmiNf    := space(001)
Private cSerasa   := space(001)
Private cConfPa   := space(001)
Private cEnvBco   := space(001)
Private cEnvBol   := space(001)
Private cTipVen   := space(001)
Private cRegVen   := space(001)
Private cDiaSem   := space(002)
Private cRegFer   := space(001)
Private cSemUte   := space(002)
Private cSemCon   := space(001)
Private cEmiRec   := space(001)
Private cVlrTot   := space(001)
Private cRecAut   := space(001)
Private cCarFat   := space(001)
Private cUniLoc   := space(001)
Private cVtotnf   := space(001)
Private cCobTer   := space(001)
Private cRepEmp   := space(001)
Private cCisepa   := space(001)
Private cSigla    := space(002)
Private cVldFat   := space(001)
Private cIdConf   := space(015)
Private cIdCont   := space(015)
Private cIdPgto   := space(015)
Private cNomcob   := space(150)
Private cNomctr   := space(150)
Private cCpfctr   := space(011)
Private cDddctr   := space(002)
Private cTelctr   := space(009)
Private cRamctr   := space(009)
Private cMailct   := space(100)
Private cCarctr   := space(100)
Private cMaibol   := space(100)
Private cCodbco   := space(003)
Private cAgenci   := space(005)
Private cCtacre   := space(010)
Private cDtpave   := space(020)
Private cDiaven   := space(002)
Private cQtdias   := space(002)
Private cCep      := space(008)
Private cLograd   := space(150)
Private cCndere   := space(150)
Private cNumero   := space(010)
Private cComple   := space(050)
Private cBairro   := space(050)
Private cCoibge   := space(050)
Private cCidade   := space(050)
Private cEstado   := space(002)
Private cMsg      := space(150)
Private cBcocon   := space(003)
Private cAgeout   := space(005)
Private cCtacon   := space(010)
Private cObsrec   := space(150)
Private cObscar   := space(150)
Private cObsnf    := space(150)
Private cMailnf   := space(100)
Private cQtddia   := space(002)
Private cDiater   := space(002)
Private cLocvin   := space(015)
Private cUnresp   := space(015)
Private cDocres   := space(014)
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""
Private cAreaSe   := space(100)
Private cCarBco   := space(003)
Private cCarAge   := space(005)
Private cCarCc    := space(010)
Private cCarDcc   := space(002)

DbSelectArea("CC2")
CC2->(DbSetOrder(01))

DbSelectArea("ZC3")
ZC3->(DbSetOrder(01))

DbSelectArea("ZCI")
ZCI->(DbSetOrder(01))

DbSelectarea("ZCN")
ZCN->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"A")
if !Empty(cErro)
	U_GrvLogKa("CINTK02", "PUT", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

//Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("CONFIGCOB",oJson:toJSON(),"PUT")
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK02", "DW3PUT", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

// Realiza a grava��o na tabela ZC3
GravaZc3(oJson)

U_GrvLogKa("CINTK02", "PUT", "1", "Atualiza��o realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Atualiza��o realizada com sucesso")

/*/{Protheus.doc} DELETE
Realiza a desativa��o das configura��es de Cobran�a
@author carlos.henrique
@since 01/03/2019
@version undefined

@type function
/*/
WSMETHOD DELETE WSSERVICE CONFIGCOB

Local cErro

Local aRet  := {}
Local oJson := Nil

Private cJson     := Nil
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""

DbSelectArea("ZC3")
ZC3->(DbSetOrder(01))

DbSelectArea("ZCI")
ZCI->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"E")
if !Empty(cErro)
	U_GrvLogKa("CINTK02", "DELETE", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

//Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("CONFIGCOB",oJson:toJSON(),"DELETE")
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK02", "DW3DELETE", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

// Destiva o registro na tabela ZC3
Begin Transaction
	RecLock("ZC3",.F.)
	ZC3->ZC3_STATUS:= "2"
	ZC3->(MsUnLock())
End Transaction

U_GrvLogKa("CINTK02", "DELETE", "1", "Desativa��o realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Desativa��o realizada com sucesso")

/*/{Protheus.doc} GET
Realiza a consulta das configura��es de Cobran�a
@author Danilo Jos� Grodzicki
@since 21/09/2019
@/version undefined

@type function
/*/
WSMETHOD GET WSSERVICE CONFIGCOB

Local cErro

Local oJson := Nil
Local cJson := ""

Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""

DbSelectArea("ZC3")
ZC3->(DbSetOrder(01))

DbSelectArea("ZCI")
ZCI->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"C")
if !Empty(cErro)
	U_GrvLogKa("CINTK02", "GET", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

cJson := '{'
cJson += '	"CONFIGURACAO": {'
cJson += '		"id": "' + EncodeUTF8(AllTrim(ZC3->ZC3_IDCOBR), "cp1252") + '",'
cJson += '		"nome": "' + EncodeUTF8(AllTrim(ZC3->ZC3_NOMCOB), "cp1252") + '",'
cJson += '		"padrao": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CONFPA), "cp1252") + '",'
cJson += '		"idContrato": "' + EncodeUTF8(AllTrim(ZC3->ZC3_IDCONT), "cp1252") + '",'
cJson += '		"idConfiguracaofaturamento": "' + EncodeUTF8(AllTrim(ZC3->ZC3_IDPGTO), "cp1252") + '",'
cJson += '		"DADOSCONTATOCOBRANCA": {'
cJson += '			"nome": "' + EncodeUTF8(AllTrim(ZC3->ZC3_NOMCTR), "cp1252") + '",'
cJson += '			"documento": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CPFCTR), "cp1252") + '",'
cJson += '			"ddd": "' + EncodeUTF8(AllTrim(ZC3->ZC3_DDDCTR), "cp1252") + '",'
cJson += '			"telefone": "' + EncodeUTF8(AllTrim(ZC3->ZC3_TELCTR), "cp1252") + '",'
cJson += '			"ramal": "' + EncodeUTF8(AllTrim(ZC3->ZC3_RAMCTR), "cp1252") + '",'
cJson += '			"email": "' + EncodeUTF8(AllTrim(ZC3->ZC3_MAILCT), "cp1252") + '",'
cJson += '			"cargo": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CARCTR), "cp1252") + '"'
cJson += '		},'
cJson += '		"FICHACOBRANCABANCARIA": {'
cJson += '			"enviaBanco": "' + EncodeUTF8(AllTrim(ZC3->ZC3_ENVBCO), "cp1252") + '",'
cJson += '			"enviaBoletoEmail": "' + EncodeUTF8(AllTrim(ZC3->ZC3_ENVBOL), "cp1252") + '",'
cJson += '			"email": "' + EncodeUTF8(AllTrim(ZC3->ZC3_MAIBOL), "cp1252") + '",'
cJson += '			"CREDITOEMCONTA": {'
cJson += '				"banco": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CODBCO), "cp1252") + '",'
cJson += '				"agencia": "' + EncodeUTF8(AllTrim(ZC3->ZC3_AGENCI), "cp1252") + '",'
cJson += '				"conta": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CTACRE), "cp1252") + '"'
cJson += '			},'
cJson += '			"DATADEVENCIMENTO": {'
cJson += '				"tipo": "' + EncodeUTF8(AllTrim(ZC3->ZC3_TIPVEN), "cp1252") + '",'
cJson += '				"TPPADRAO": {'
cJson += '					"data": "' + EncodeUTF8(AllTrim(ZC3->ZC3_PRPAVE), "cp1252") + '"'
cJson += '				},'
cJson += '				"TPDIAVENCIMENTO": {'
cJson += '					"diaVencimento": "' + EncodeUTF8(AllTrim(ZC3->ZC3_DIAVEN), "cp1252") + '",'
cJson += '					"competencia": "' + EncodeUTF8(AllTrim(ZC3->ZC3_COMPET), "cp1252") + '",'
cJson += '					"diaSemana": "' + EncodeUTF8(AllTrim(ZC3->ZC3_REGVEN), "cp1252") + '",'
cJson += '					"regraFeriado": "' + EncodeUTF8(AllTrim(ZC3->ZC3_REGFER), "cp1252") + '"'
cJson += '				},'
cJson += '				"TPDIASUTEISCORRIDOS": {'
cJson += '					"regra": "' + EncodeUTF8(AllTrim(ZC3->ZC3_UTEIS), "cp1252") + '",'
cJson += '					"qtdDias": "' + EncodeUTF8(AllTrim(ZC3->ZC3_QTDIAS), "cp1252") + '",'
cJson += '					"dia": "' + EncodeUTF8(AllTrim(ZC3->ZC3_SEMUTE), "cp1252") + '",'
cJson += '					"regraFeriadoConsiderar": "' + EncodeUTF8(AllTrim(ZC3->ZC3_SEMCON), "cp1252") + '"'
cJson += '				}'
cJson += '			},'
cJson += '			"ENDERECO": {'
cJson += '				"cep": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CEP), "cp1252") + '",'
cJson += '				"logradouro": "' + EncodeUTF8(AllTrim(ZC3->ZC3_LOGRAD), "cp1252") + '",'
cJson += '				"endereco": "' + EncodeUTF8(AllTrim(ZC3->ZC3_ENDERE), "cp1252") + '",'
cJson += '				"numero": "' + EncodeUTF8(AllTrim(ZC3->ZC3_NUMERO), "cp1252") + '",'
cJson += '				"complemento": "' + EncodeUTF8(AllTrim(ZC3->ZC3_COMPLE), "cp1252") + '",'
cJson += '				"bairro": "' + EncodeUTF8(AllTrim(ZC3->ZC3_BAIRRO), "cp1252") + '",'
cJson += '				"codigoIBGE": "' + EncodeUTF8(AllTrim(ZC3->ZC3_COIBGE), "cp1252") + '",'
cJson += '				"cidade": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CIDADE), "cp1252") + '",'
cJson += '				"uf": "' + EncodeUTF8(AllTrim(ZC3->ZC3_ESTADO), "cp1252") + '",'
cJson += '				"menssagem": "' + EncodeUTF8(AllTrim(ZC3->ZC3_MSG), "cp1252") + '"'
cJson += '			}'
cJson += '		},'
cJson += '		"OUTRASCONFIGURACOES": {'
cJson += '			"RECIBO": {'
cJson += '				"emite": "' + EncodeUTF8(AllTrim(ZC3->ZC3_EMIREC), "cp1252") + '",'
cJson += '				"ValorTotal": "' + EncodeUTF8(AllTrim(ZC3->ZC3_VLRTOT), "cp1252") + '",'
cJson += '				"ReciboAutomatico": "' + EncodeUTF8(AllTrim(ZC3->ZC3_RECAUT), "cp1252") + '",'
cJson += '				"banco": "' + EncodeUTF8(AllTrim(ZC3->ZC3_BCOCON), "cp1252") + '",'
cJson += '				"agencia": "' + EncodeUTF8(AllTrim(ZC3->ZC3_AGEOUT), "cp1252") + '",'
cJson += '				"conta": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CTACON), "cp1252") + '",'
cJson += '				"observacao": "' + EncodeUTF8(AllTrim(ZC3->ZC3_OBSREC), "cp1252") + '"'
cJson += '			},'
cJson += '			"CARTAFATURA": {'
cJson += '				"emite": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CARFAT), "cp1252") + '",'
cJson += '				"observacao": "' + EncodeUTF8(AllTrim(ZC3->ZC3_OBSCAR), "cp1252") + '",'
cJson += '				"unificaLocal": "' + EncodeUTF8(AllTrim(ZC3->ZC3_UNILOC), "cp1252") + '",'
cJson += '				"banco": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CARBCO), "cp1252") + '",'
cJson += '				"agencia": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CARAGE), "cp1252") + '",'
cJson += '				"conta": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CARCC), "cp1252") + '",'
cJson += '				"codigoOperacional": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CARDCC), "cp1252") + '"'
cJson += '			},'
cJson += '			"NOTAFISCAL": {'
cJson += '				"emite": "' + EncodeUTF8(AllTrim(ZC3->ZC3_EMINF), "cp1252") + '",'
cJson += '				"observacao": "' + EncodeUTF8(AllTrim(ZC3->ZC3_OBSNF), "cp1252") + '",'
cJson += '				"email": "' + EncodeUTF8(AllTrim(ZC3->ZC3_MAILNF), "cp1252") + '",'
cJson += '				"valorTotal": "' + EncodeUTF8(AllTrim(ZC3->ZC3_VTOTNF), "cp1252") + '"'
cJson += '			},'
cJson += '			"COBRANCASERASA": {'
cJson += '				"envia": "' + EncodeUTF8(AllTrim(ZC3->ZC3_SERASA), "cp1252") + '",'
cJson += '				"qtdDias": "' + EncodeUTF8(AllTrim(ZC3->ZC3_QTDDIA), "cp1252") + '"'
cJson += '			},'
cJson += '			"COBRANCATERCEIRO": {'
cJson += '				"envia": "' + EncodeUTF8(AllTrim(ZC3->ZC3_COBTER), "cp1252") + '",'
cJson += '				"qtdDias": "' + EncodeUTF8(AllTrim(ZC3->ZC3_DIATER), "cp1252") + '"'
cJson += '			},'
cJson += '			"RepasseEmpresa": "' + EncodeUTF8(AllTrim(ZC3->ZC3_REPEMP), "cp1252") + '",'
cJson += '			"CISeparada": "' + EncodeUTF8(AllTrim(ZC3->ZC3_CISEPA), "cp1252") + '",'
cJson += '			"siglaExibicaoRelatorio": "' + EncodeUTF8(AllTrim(ZC3->ZC3_SIGLA), "cp1252") + '"'
cJson += '		},'
cJson += '		"LOCAISCONTRATOSVINCULADOS": {'
cJson += '			"idLocalContratoResponsavel": "' + EncodeUTF8(AllTrim(ZC3->ZC3_LOCVIN), "cp1252") + '",'
cJson += '			"IdUnidade": "' + EncodeUTF8(AllTrim(ZC3->ZC3_UNRESP), "cp1252") + '",'
cJson += '			"documento": "' + EncodeUTF8(AllTrim(ZC3->ZC3_DOCRES), "cp1252") + '",'

if ZCI->(DbSeek(xFilial("ZCI")+ZC3->ZC3_IDCOBR))
	cJson += '			"LOCAISCONTRATOS": ['
	while AllTrim(ZCI->ZCI_FILIAL+ZCI->ZCI_IDCOBR) == AllTrim(xFilial("ZCI")+ZC3->ZC3_IDCOBR) .and. ZCI->(!Eof())
		cJson += '			{'
		cJson += '				"IdContrato": "' + EncodeUTF8(AllTrim(ZCI->ZCI_IDCONT), "cp1252") + '",'
		cJson += '				"IdLocalContrato": "' + EncodeUTF8(AllTrim(ZCI->ZCI_LOCCTR), "cp1252") + '"'
		cJson += '			}'
		ZCI->(DbSkip())
		if AllTrim(ZCI->ZCI_FILIAL+ZCI->ZCI_IDCOBR) == AllTrim(xFilial("ZCI")+ZC3->ZC3_IDCOBR) .and. ZCI->(!Eof())
			cJson += ','
		endif
	enddo
	cJson += '			]'
else
	cJson += '			"LOCAISCONTRATOS": [ ]'
endif

cJson += '	    },'
cJson += '		"validaFaturamento": "' + EncodeUTF8(AllTrim(ZC3->ZC3_VLDFAT), "cp1252") + '"'
cJson += '	}'
cJson += '}'

::SetResponse(cJson)

Return .T.

/*/{Protheus.doc} ValoJson
Valida os dados do oJson
@author Danilo Jos� Grodzicki
@since 21/09/2019
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
Static Function ValoJson(oJson,cTipo)

Local nI
Local cContrato
Local cLocalCtr

Local cVldAux := ""

// Verifica se enviou o ID da configura��o de cobran�a
cIdConf := oJson["CONFIGURACAO"]:GetJsonText("id")
if Empty(cIdConf)
	Return("O ID da configura��o de cobran�a � obrig�torio.")
endif

if cTipo == "C" .or. cTipo == "E" // Consulta ou Exclus�o
	
	// Verifica se o ID de cobran�a est� cadastrado
	if !ZC3->(DbSeek(xFilial("ZC3") + Padr(AllTrim(cIdConf),TamSX3("ZC3_IDCOBR")[1]," ") ))
		Return("O ID da configura��o de cobran�a " + AllTrim(cIdConf) + " n�o existe.")
	else
		Return("")
	endif
		
endif

// Verifica se enviou o ID do local do contrato
cIdCont := oJson["CONFIGURACAO"]:GetJsonText("idContrato")
if Empty(cIdCont)
	Return("O c�digo do contrato � obrigat�rio.")
endif

// Verifica se enviou o ID da configura��o do faturamento
cIdPgto := oJson["CONFIGURACAO"]:GetJsonText("idConfiguracaofaturamento")
if Empty(cIdPgto)
	Return("O ID da configura��o do faturamento � obrigat�rio.")
endif	

// Verifica se existe o id do contrato e local do contrato
for nI = 1 to Len(oJson["CONFIGURACAO"]["LOCAISCONTRATOSVINCULADOS"]["LOCAISCONTRATOS"])
	cContrato := Padr(AllTrim(oJson["CONFIGURACAO"]["LOCAISCONTRATOSVINCULADOS"]["LOCAISCONTRATOS"][nI]:GetJsonText("IdContrato")),TamSX3("ZC1_CODIGO")[1]," ")
	cLocalCtr := Padr(AllTrim(oJson["CONFIGURACAO"]["LOCAISCONTRATOSVINCULADOS"]["LOCAISCONTRATOS"][nI]:GetJsonText("IdLocalContrato")),TamSX3("ZC1_LOCCTR")[1]," ")
	
	if !ZC1->(DbSeek(xFilial("ZC1") + cContrato + cLocalCtr))
		cVldAux:= "O contrato " + AllTrim(cContrato) + " e o local do contrato " + AllTrim(cLocalCtr) + " n�o existe."
		EXIT
	endif	
Next

if !EMPTY(cVldAux)
	lErroTenta := .T.
	Return(cVldAux)
endif

// Verifica se o ID da configura��o do faturamento e id do contrato j� est� cadastrado
if !ZC4->(DbSeek(xFilial("ZC4") + Padr(AllTrim(cIdPgto),TamSX3("ZC4_IDFATU")[1]," ") + Padr(AllTrim(cIdCont),TamSX3("ZC4_IDCONT")[1]," ")))
	lErroTenta := .T.
	Return("O ID da configura��o de faturamento " + AllTrim(cIdPgto) + " para o ID do contrato " + AllTrim(cIdCont) + " n�o existe.")
Endif	

// Verifica se a configura��o padr�o � v�lida
cConfPa := oJson["CONFIGURACAO"]:GetJsonText("padrao")
if Empty(cConfPa) .or. !(cConfPa $ "01")
	Return("Configura��o padr�o " + AllTrim(cConfPa) + " inv�lido.")
endif

// Verifica se envia cobran�a para o banco � v�lido
cEnvBco := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]:GetJsonText("enviaBanco")
if Empty(cEnvBco) .or. !(cEnvBco $ "01")
	Return("Envia cobran�a para o banco " + AllTrim(cEnvBco) + " inv�lido.")
endif

// Verifica se envia boleto e-mail � v�lido
cEnvBol := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]:GetJsonText("enviaBoletoEmail")
if Empty(cEnvBol) .or. !(cEnvBol $ "01")
	Return("Envia boleto e-mail " + AllTrim(cEnvBol) + " inv�lido.")
endif

// Verifica se tipo data vencimento boleto � v�lido
cTipVen := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]:GetJsonText("tipo")
if Empty(cTipVen) .or. !(cTipVen $ "123")
	Return("Tipo data vencimento boleto " + AllTrim(cTipVen) + " inv�lido.")
endif

if cTipVen == "1"  // Padr�o
	
	//N�o validar como obrigat�rio
	/*
	cDtpave := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]["TPPADRAO"]:GetJsonText("data")
	if Empty(cDtpave)
		Return("Data de vencimento padr�o " + AllTrim(cDtpave) + " inv�lido.")
	endif
	*/

elseif cTipVen == "2"  // Dia de vencimento 

	// Verifica se regra vencimento boleto � v�lido
	cDiaVen := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]["TPDIAVENCIMENTO"]:GetJsonText("diaVencimento")
	if Empty(cDiaVen)
		Return("Dia vencimento " + AllTrim(cDiaVen) + " inv�lido.")
	endif

	cCompet:= oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]["TPDIAVENCIMENTO"]:GetJsonText("competencia")
	if Empty(cCompet) .or. !(cCompet $ "12")
		Return("Compet�ncia " + AllTrim(cCompet) + " inv�lida.")
	endif
	
	/*
	// Verifica se dia semana � v�lido
	cDiaSem := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]["TPDIAVENCIMENTO"]:GetJsonText("diaSemana")
	if Empty(cDiaSem) .or. !(cDiaSem $ "12345")
		Return("Dia semana " + AllTrim(cDiaSem) + " inv�lido.")
	endif
	
	// Verifica se regra feriado � v�lido
	cRegFer := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]["TPDIAVENCIMENTO"]:GetJsonText("regraFeriado")
	if Empty(cRegFer) .or. !(cRegFer $ "12")
		Return("Regra feriado " + AllTrim(cRegFer) + " inv�lido.")
	endif
	*/
	
elseif cTipVen == "3"  // Dias �teis ou corridos

	// Verifica se dias �teis/corridos � v�lido
	cUteis := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]["TPDIASUTEISCORRIDOS"]:GetJsonText("regra")
	if Empty(cUteis) .or. !(cUteis $ "12")
		Return("Dias �teis/corridos " + AllTrim(cUteis) + " inv�lido.")
	endif
	
	/*
	// Verifica se dia semana �teis/corridos � v�lido
	cSemUte := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]["TPDIASUTEISCORRIDOS"]:GetJsonText("dia")
	if Empty(cSemUte) .or. !(cSemUte $ "12345")
		Return("Dia semana �teis/corridos " + AllTrim(cSemUte) + " inv�lido.")
	endif
	
	// Verifica se feriado considerar � v�lido
	cSemCon := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]["TPDIASUTEISCORRIDOS"]:GetJsonText("regraFeriadoConsiderar")
	if Empty(cSemCon) .or. !(cSemCon $ "12")
		Return("Se feriado considerar " + AllTrim(cSemCon) + " inv�lido.")
	endif
	*/

endif

cEstado := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["ENDERECO"]:GetJsonText("uf")
cCoibge := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["ENDERECO"]:GetJsonText("codigoIBGE")

// Verifica se o estado e c�digo do munic�pio do endere�o da empresa s�o v�lidos
if !CC2->(DbSeek(xFilial("CC2")+cEstado+Right(cCoibge,5)))
	Return("O estado " + AllTrim(cEstado) + " e/ou c�digo do munic�pio " + AllTrim(cCoibge) + " do endere�o da empresa inv�lido.")
endif
cCidade := AllTrim(CC2->CC2_MUN)

// Verifica se emite recibo � v�lido
cEmiRec := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["RECIBO"]:GetJsonText("emite")
if Empty(cEmiRec) .or. !(cEmiRec $ "12")
	Return("Se emite recibo " + AllTrim(cEmiRec) + " inv�lido.")
endif

if cEmiRec == "1"
	// Verifica com valor total � v�lido
	cVlrTot := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["RECIBO"]:GetJsonText("ValorTotal")
	if Empty(cVlrTot) .or. !(cVlrTot $ "12")
		Return("Com valor total " + AllTrim(cVlrTot) + " inv�lido.")
	endif
	
	// Verifica se recibo autom�tico � v�lido
	cRecAut := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["RECIBO"]:GetJsonText("ReciboAutomatico")
	if Empty(cRecAut) .or. !(cRecAut $ "12")
		Return("Recibo autom�tico " + AllTrim(cRecAut) + " inv�lido.")
	endif
endif

// Verifica se emite carta fatura � v�lido
cCarFat := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["CARTAFATURA"]:GetJsonText("emite")
if Empty(cCarFat) .or. !(cCarFat $ "12")
	Return("Emite carta fatura " + AllTrim(cCarFat) + " inv�lido.")
endif

if cCarFat == "1"
	// Verifica se unifica local � v�lido
	cUniLoc := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["CARTAFATURA"]:GetJsonText("unificaLocal")
	if Empty(cUniLoc) .or. !(cUniLoc $ "12")
		Return("Unifica local " + AllTrim(cUniLoc) + " inv�lido.")
	endif
endif

// Verifica se emite NF � v�lido
cEmiNf := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["NOTAFISCAL"]:GetJsonText("emite")
if Empty(cEmiNf) .or. !(cEmiNf $ "12")
	Return("Emite NF " + AllTrim(cEmiNf) + " inv�lido.")
endif

if cEmiNf == "1"
	// Verifica valor total � v�lido
	cVtotnf := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["NOTAFISCAL"]:GetJsonText("valorTotal")
	if Empty(cVtotnf) .or. !(cVtotnf $ "12")
		Return("Valor total " + AllTrim(cVtotnf) + " inv�lido.")
	endif
endif

// Verifica se cobran�a serasa � v�lido
cSerasa := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["COBRANCASERASA"]:GetJsonText("envia")
if Empty(cSerasa) .or. !(cSerasa $ "12")
	Return("Cobran�a serasa " + AllTrim(cSerasa) + " inv�lido.")
endif

// Verifica se cobran�a terceiro � v�lido
cCobTer := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["COBRANCATERCEIRO"]:GetJsonText("envia")
if Empty(cCobTer) .or. !(cCobTer $ "12")
	Return("Cobran�a terceiro " + AllTrim(cCobTer) + " inv�lido.")
endif

// Verifica se repasse para empresa � v�lido
cRepEmp := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]:GetJsonText("RepasseEmpresa")
if Empty(cRepEmp) .or. !(cRepEmp $ "12")
	Return("Repasse para empresa " + AllTrim(cRepEmp) + " inv�lido.")
endif

// Verifica se CI separada � v�lido
cCisepa := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]:GetJsonText("CISeparada")
if Empty(cCisepa) .or. !(cCisepa $ "12")
	Return("CI separada " + AllTrim(cCisepa) + " inv�lido.")
endif

// Verifica a sigla para exibi��o no relat�rio
if cCisepa == "2"
	cSigla := AllTrim(oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]:GetJsonText("siglaExibicaoRelatorio"))
	if Empty(cSigla) .or. !(cSigla $ "CICO")
		Return("Sigla para ser exibida em relat�rios " + AllTrim(cSigla) + " inv�lido.")
	endif
endif

// Verifica se validar faturamento � v�lido
cVldFat := oJson["CONFIGURACAO"]:GetJsonText("validaFaturamento")
if Empty(cVldFat) .or. !(cVldFat $ "12")
	Return("Validar faturamento " + AllTrim(cVldFat) + " inv�lido.")
endif

// Verifica se enviou a unidade CIEE
//cUnresp := AllTrim(oJson["CONFIGURACAO"]["LOCAISCONTRATOSVINCULADOS"]:GetJsonText("idUnidade"))
//if Empty(cUnresp) .or. !ZCN->(DbSeek(xFilial("ZCN")+cUnresp))
//	Return("Unidade CIEE respons�vel " + AllTrim(cUnresp) + " inv�lida.")
//endif

Return("")

/*/{Protheus.doc} GravaZc3
Realiza a grava��o na tabela ZC3
@author Danilo Jos� Grodzicki
@since 21/09/2019
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
Static Function GravaZc3(oJson)

Local nI

Local lCtrNormal := .T.

cNomcob := DecodeUTF8(oJson["CONFIGURACAO"]:GetJsonText("nome"))
cNomctr := DecodeUTF8(oJson["CONFIGURACAO"]["DADOSCONTATOCOBRANCA"]:GetJsonText("nome"))
cCpfctr := oJson["CONFIGURACAO"]["DADOSCONTATOCOBRANCA"]:GetJsonText("documento")
cDddctr := oJson["CONFIGURACAO"]["DADOSCONTATOCOBRANCA"]:GetJsonText("ddd")
cTelctr := oJson["CONFIGURACAO"]["DADOSCONTATOCOBRANCA"]:GetJsonText("telefone")
cRamctr := oJson["CONFIGURACAO"]["DADOSCONTATOCOBRANCA"]:GetJsonText("ramal")
cMailct := DecodeUTF8(oJson["CONFIGURACAO"]["DADOSCONTATOCOBRANCA"]:GetJsonText("email"))
cCarctr := DecodeUTF8(oJson["CONFIGURACAO"]["DADOSCONTATOCOBRANCA"]:GetJsonText("cargo"))
cAreaSe := DecodeUTF8(oJson["CONFIGURACAO"]["DADOSCONTATOCOBRANCA"]:GetJsonText("areaSetor"))
cMaibol := DecodeUTF8(oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]:GetJsonText("email"))
cCodbco := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["CREDITOEMCONTA"]:GetJsonText("banco")
cAgenci := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["CREDITOEMCONTA"]:GetJsonText("agencia")
cCtacre := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["CREDITOEMCONTA"]:GetJsonText("conta")
cDtpave := DecodeUTF8(oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]["TPPADRAO"]:GetJsonText("data"))
cDiaVen := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]["TPDIAVENCIMENTO"]:GetJsonText("diaVencimento")
cCompet := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]["TPDIAVENCIMENTO"]:GetJsonText("competencia")
cDiaSem := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]["TPDIAVENCIMENTO"]:GetJsonText("diaSemana")
cRegFer := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]["TPDIAVENCIMENTO"]:GetJsonText("regraFeriado")
cQtdias := Str(Val(oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["DATADEVENCIMENTO"]["TPDIASUTEISCORRIDOS"]:GetJsonText("qtdDias")),2,0)
cCep    := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["ENDERECO"]:GetJsonText("cep")
cLograd := DecodeUTF8(oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["ENDERECO"]:GetJsonText("logradouro"))
cCndere := DecodeUTF8(oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["ENDERECO"]:GetJsonText("endereco"))
cNumero := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["ENDERECO"]:GetJsonText("numero")
cComple := DecodeUTF8(oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["ENDERECO"]:GetJsonText("complemento"))
cBairro := DecodeUTF8(oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["ENDERECO"]:GetJsonText("bairro"))
cCoibge := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["ENDERECO"]:GetJsonText("codigoIBGE")
//cCidade := DecodeUTF8(oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["ENDERECO"]:GetJsonText("cidade"))
cEstado := oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["ENDERECO"]:GetJsonText("uf")
cMsg    := DecodeUTF8(oJson["CONFIGURACAO"]["FICHACOBRANCABANCARIA"]["ENDERECO"]:GetJsonText("mensagem"))
cBcocon := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["RECIBO"]:GetJsonText("banco")
cAgeout := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["RECIBO"]:GetJsonText("agencia")
cCtacon := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["RECIBO"]:GetJsonText("conta")
cObsrec := DecodeUTF8(oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["RECIBO"]:GetJsonText("observacao"))
cObscar := DecodeUTF8(oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["CARTAFATURA"]:GetJsonText("observacao"))
cCarBco := DecodeUTF8(oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["CARTAFATURA"]:GetJsonText("banco"))
cCarAge := DecodeUTF8(oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["CARTAFATURA"]:GetJsonText("agencia"))
cCarCc  := DecodeUTF8(oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["CARTAFATURA"]:GetJsonText("conta"))
cCarDcc := DecodeUTF8(oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["CARTAFATURA"]:GetJsonText("codigoOperacional"))
cObsnf  := DecodeUTF8(oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["NOTAFISCAL"]:GetJsonText("observacao"))
cMailnf := DecodeUTF8(oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["NOTAFISCAL"]:GetJsonText("email"))
cQtddia := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["COBRANCASERASA"]:GetJsonText("qtdDias")
cDiater := oJson["CONFIGURACAO"]["OUTRASCONFIGURACOES"]["COBRANCATERCEIRO"]:GetJsonText("qtdDias")
cLocvin := oJson["CONFIGURACAO"]["LOCAISCONTRATOSVINCULADOS"]:GetJsonText("idLocalContratoResponsavel")
cUnresp := AllTrim(oJson["CONFIGURACAO"]["LOCAISCONTRATOSVINCULADOS"]:GetJsonText("idUnidade"))
cDocres := oJson["CONFIGURACAO"]["LOCAISCONTRATOSVINCULADOS"]:GetJsonText("documento")

// Verifica se � contrato normal
for nI = 1 to Len(oJson["CONFIGURACAO"]["LOCAISCONTRATOSVINCULADOS"]["LOCAISCONTRATOS"])
	if AllTrim(cIdCont) <> AllTrim(oJson["CONFIGURACAO"]["LOCAISCONTRATOSVINCULADOS"]["LOCAISCONTRATOS"][nI]:GetJsonText("IdContrato"))
		lCtrNormal := .F.
		exit
	endif
Next

//if !lInclui  // Se altera��o, apaga os registros da ZCI.
if ZC3->(DbSeek(xFilial("ZC3") + Padr(AllTrim(cIdConf),TamSX3("ZC3_IDCOBR")[1]," ") + Padr(AllTrim(cIdCont),TamSX3("ZC3_IDCONT")[1]," ") + Padr(AllTrim(cIdPgto),TamSX3("ZC3_IDPGTO")[1]," ")))
	if ZCI->(DbSeek(xFilial("ZCI")+cIdConf))
		while AllTrim(ZCI->ZCI_FILIAL+ZCI->ZCI_IDCOBR) == AllTrim(xFilial("ZCI")+cIdConf) .and. ZCI->(!Eof())
			RecLock("ZCI",.F.)
				ZCI->(DbDelete())
			ZCI->(MsUnLock())
			ZCI->(DbSkip())
		enddo
	endif
endif

Begin Transaction

	Sleep(500)

	ZC3->(DbSetOrder(01))
	if ZC3->(DbSeek(xFilial("ZC3") + Padr(AllTrim(cIdConf),TamSX3("ZC3_IDCOBR")[1]," ") + Padr(AllTrim(cIdCont),TamSX3("ZC3_IDCONT")[1]," ") + Padr(AllTrim(cIdPgto),TamSX3("ZC3_IDPGTO")[1]," ")))
		RecLock("ZC3",.F.)
	else
		RecLock("ZC3",.T.)
	endif
		ZC3->ZC3_FILIAL := xFilial("ZC3")
		ZC3->ZC3_IDCOBR := cIdConf
		ZC3->ZC3_NOMCOB := cNomcob
		ZC3->ZC3_CONFPA := cConfPa
		ZC3->ZC3_IDCONT := cIdCont
		ZC3->ZC3_IDPGTO := cIdPgto
		ZC3->ZC3_NOMCTR := cNomctr
		ZC3->ZC3_CPFCTR := cCpfctr
		ZC3->ZC3_DDDCTR := cDddctr
		ZC3->ZC3_TELCTR := cTelctr
		ZC3->ZC3_RAMCTR := cRamctr
		ZC3->ZC3_MAILCT := cMailct
		ZC3->ZC3_CARCTR := cCarctr
		ZC3->ZC3_ENVBCO := cEnvBco
		ZC3->ZC3_ENVBOL := cEnvBol
		ZC3->ZC3_MAIBOL := cMaibol
		ZC3->ZC3_CODBCO := cCodbco
		ZC3->ZC3_AGENCI := cAgenci
		ZC3->ZC3_CTACRE := cCtacre
		ZC3->ZC3_TIPVEN := cTipVen
		ZC3->ZC3_PRPAVE := cDtpave
		ZC3->ZC3_DIAVEN := cDiaven
		ZC3->ZC3_COMPET := cCompet
		ZC3->ZC3_REGVEN := cRegVen
		ZC3->ZC3_DIASEM := cDiaSem
		ZC3->ZC3_REGFER := cRegFer
		ZC3->ZC3_UTEIS  := cUteis
		ZC3->ZC3_QTDIAS := cQtdias
		ZC3->ZC3_SEMUTE := cSemUte
		ZC3->ZC3_SEMCON := cSemCon
		ZC3->ZC3_CEP    := cCep
		ZC3->ZC3_LOGRAD := cLograd
		ZC3->ZC3_ENDERE := cCndere
		ZC3->ZC3_NUMERO := cNumero
		ZC3->ZC3_COMPLE := cComple
		ZC3->ZC3_BAIRRO := cBairro
		ZC3->ZC3_COIBGE := cCoibge
		ZC3->ZC3_CIDADE := cCidade
		ZC3->ZC3_ESTADO := cEstado
		ZC3->ZC3_MSG    := cMsg
		ZC3->ZC3_EMIREC := cEmiRec
		ZC3->ZC3_VLRTOT := cVlrTot
		ZC3->ZC3_RECAUT := cRecAut
		ZC3->ZC3_BCOCON := cBcocon
		ZC3->ZC3_AGEOUT := cAgeout
		ZC3->ZC3_CTACON := cCtacon
		ZC3->ZC3_OBSREC := cObsrec
		ZC3->ZC3_CARFAT := cCarFat
		ZC3->ZC3_OBSCAR := cObscar
		ZC3->ZC3_UNILOC := cUniLoc
		ZC3->ZC3_EMINF  := cEmiNf
		ZC3->ZC3_OBSNF  := cObsnf
		ZC3->ZC3_MAILNF := cMailnf
		ZC3->ZC3_VTOTNF := cVtotnf
		ZC3->ZC3_SERASA := cSerasa
		ZC3->ZC3_QTDDIA := cQtddia
		ZC3->ZC3_COBTER := cCobTer
		ZC3->ZC3_DIATER := cDiater
		ZC3->ZC3_REPEMP := cRepEmp
		ZC3->ZC3_CISEPA := cCisepa
		ZC3->ZC3_SIGLA  := cSigla
		ZC3->ZC3_LOCVIN := cLocvin
		ZC3->ZC3_UNRESP := cUnresp
		ZC3->ZC3_DOCRES := cDocres
		ZC3->ZC3_VLDFAT := cVldFat
		ZC3->ZC3_DTINTE := Date()
		ZC3->ZC3_HRINTE := Time()
		ZC3->ZC3_JSON   := cJson
//		ZC3->ZC3_JSONUN := U_CINTK13(ZC3->ZC3_UNRESP)
		ZC3->ZC3_STATUS := "1"
		ZC3->ZC3_ARESET := cAreaSe
		ZC3->ZC3_CARBCO := cCarBco
		ZC3->ZC3_CARAGE := cCarAge
		ZC3->ZC3_CARCC  := cCarCc
		ZC3->ZC3_CARDCC := cCarDcc
	ZC3->(MsUnLock())

	// Grava os contratos e locais do contrato
	for nI = 1 to Len(oJson["CONFIGURACAO"]["LOCAISCONTRATOSVINCULADOS"]["LOCAISCONTRATOS"])

		RecLock("ZCI",.T.)
			ZCI->ZCI_FILIAL := xFilial("ZCI")
			ZCI->ZCI_IDCOBR := cIdConf
			ZCI->ZCI_IDUNIF := cIdCont
			ZCI->ZCI_IDCONT := AllTrim(oJson["CONFIGURACAO"]["LOCAISCONTRATOSVINCULADOS"]["LOCAISCONTRATOS"][nI]:GetJsonText("IdContrato"))
			ZCI->ZCI_LOCCTR := AllTrim(oJson["CONFIGURACAO"]["LOCAISCONTRATOSVINCULADOS"]["LOCAISCONTRATOS"][nI]:GetJsonText("IdLocalContrato"))
			if lCtrNormal
				ZCI->ZCI_TPCONT := "1"  // 1 = Contrato normal
			else
				ZCI->ZCI_TPCONT := iif(Alltrim(cIdCont) == AllTrim(oJson["CONFIGURACAO"]["LOCAISCONTRATOSVINCULADOS"]["LOCAISCONTRATOS"][nI]:GetJsonText("IdContrato")),"2","3")  // 2 = Contrato Unificador / 3 = Contrato Unificado
			endif
		ZCI->(MsUnLock())

	Next

End Transaction

Return Nil