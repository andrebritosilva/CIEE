#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

/*/{Protheus.doc} CREDITOS
Serviço de conciliação de creditos não identificados
@author Danilo José Grodzicki
@since 04/11/2019
@version undefined
@type class
/*/
WSRESTFUL CREDITOS DESCRIPTION "Serviço de conciliação de creditos não identificados" FORMAT APPLICATION_JSON
	
	WSDATA BANCO      As String
	WSDATA AGENCIA    As String
	WSDATA CONTA      As String
	WSDATA RDRDE  	  As String OPTIONAL
	WSDATA RDRATE     As String OPTIONAL
	WSDATA PERIODODE  As String OPTIONAL
	WSDATA PERIODOATE As String OPTIONAL

	WSDATA idcontrato As String
	WSDATA idlocalcontrato As String
	WSDATA idmovimento As String
	WSDATA idregistro As String
	
	WSMETHOD GET getjson; 
	DESCRIPTION "Realiza a consulta de creditos não identificados";
	WSSYNTAX "/CREDITOS/NAO/IDENTIFICADOS";
	PATH "/CREDITOS/NAO/IDENTIFICADOS"
	
	WSMETHOD GET getparam;
	DESCRIPTION "Realiza a consulta de creditos não identificados";
	WSSYNTAX "/CREDITOS/NAOIDENTIFICADOS || /CREDITOS/NAOIDENTIFICADOS/{BANCO,AGENCIA,CONTA,PERIODODE,PERIODOATE}";
	PATH "/CREDITOS/NAOIDENTIFICADOS"

	WSMETHOD GET VISCRD;
	DESCRIPTION "Consulta credito identificado pelo id do movimento";
	WSSYNTAX "/creditos/identificados/{idmovimento}";
	PATH "/creditos/identificados"

	WSMETHOD GET LSTCRD;
	DESCRIPTION "Consulta de creditos identificados pelo RDR e periodo";
	WSSYNTAX "/creditos/identificados/rdr/{RDRDE,RDRATE,PERIODODE,PERIODOATE}";
	PATH "/creditos/identificados/rdr"	

	WSMETHOD POST GRVCRD DESCRIPTION "Inclusao de creditos identificados";
	WSSYNTAX "/creditos/identificados";
	PATH "/creditos/identificados"		

	WSMETHOD DELETE DELCRD;
	DESCRIPTION "Exclusao de creditos identificados";
	WSSYNTAX "/creditos/identificados/{idmovimento}";
	PATH "/creditos/identificados/"

END WSRESTFUL
 
/*/{Protheus.doc} GET
Realiza a consulta dos creditos não identificados
@author Danilo José Grodzicki
@since 04/11/2019
@/version undefined

@type function
/*/
WSMETHOD GET getjson WSSERVICE CREDITOS

Local cBanco
Local cAgencia
Local cConta
Local dDatIni
Local dDatFim

Local oJson    := Nil
Local cJson    := ""

Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

cBanco   := iif(Empty(oJson:GetJsonText("banco")),space(03),AllTrim(oJson:GetJsonText("banco")))
cAgencia := iif(Empty(oJson:GetJsonText("agencia")),space(05),AllTrim(oJson:GetJsonText("agencia")))
cConta   := iif(Empty(oJson:GetJsonText("conta")),space(10),AllTrim(oJson:GetJsonText("conta")))
dDatIni  := iif(Empty(oJson:GetJsonText("periodode")),space(08),DtoS(CtoD(oJson:GetJsonText("periodode"))))
dDatFim  := iif(Empty(oJson:GetJsonText("periodoate")),space(08),DtoS(CtoD(oJson:GetJsonText("periodoate"))))

if CoCreditos(cBanco,cAgencia,cConta,dDatIni,dDatFim,@cJson)  // Se retornou os depósitos não identificados
	::SetResponse(cJson)
else
	U_GrvLogKa("CINTK08", "GETJSON", "2", "Não foram encontrados dados para os parâmetros passados: Banco: " + cBanco + " Agencia: " + cAgencia + " Conta: " + cConta + " Período de: " + dDatIni + " Período até: " + dDatFim + ".", cJson, oJson)
	Return U_RESTERRO(Self,"Não foram encontrados dados para os parâmetros passados.")
endif

Return .T.

/*/{Protheus.doc} GET
Realiza a consulta dos creditos não identificados
@author Danilo José Grodzicki
@since 11/03/2020
@/version undefined

@type function
/*/
WSMETHOD GET getparam WSRECEIVE BANCO, AGENCIA, CONTA, PERIODODE, PERIODOATE WSSERVICE CREDITOS

Local cBanco
Local cConta
Local dDatIni
Local dDatFim
Local cAgencia

Local cJson    := ""
Local oJson    := Nil

Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""

::SetContentType('application/json')

if ValType(Self:BANCO) == "C"
	cBanco := iif(Empty(Self:BANCO),space(03),AllTrim(Self:BANCO))
else
	cBanco := space(03)
endif
if ValType(Self:AGENCIA) == "C"
	cAgencia := iif(Empty(Self:AGENCIA),space(05),AllTrim(Self:AGENCIA))
else
	cAgencia := space(05)
endif
if ValType(Self:CONTA) == "C"
	cConta := iif(Empty(Self:CONTA),space(10),AllTrim(Self:CONTA))
else
	cConta := space(10)
endif
if ValType(Self:PERIODODE) == "C"
	dDatIni := iif(Empty(Self:PERIODODE),space(08),DtoS(CtoD(Self:PERIODODE)))
else
	dDatIni := space(08)
endif
if ValType(Self:PERIODOATE) == "C"
	dDatFim := iif(Empty(Self:PERIODOATE),space(08),DtoS(CtoD(Self:PERIODOATE)))
else
	dDatFim := space(08)
endif

if CoCreditos(cBanco,cAgencia,cConta,dDatIni,dDatFim,@cJson)  // Se retornou os depósitos não identificados
	::SetResponse(cJson)
else
	U_GrvLogKa("CINTK08", "GETPARAM", "2", "Não foram encontrados dados para os parâmetros passados: Banco: " + cBanco + " Agencia: " + cAgencia + " Conta: " + cConta + " Período de: " + dDatIni + " Período até: " + dDatFim + ".", cJson, oJson)
	Return U_RESTERRO(Self,"Não foram encontrados dados para os parâmetros passados.")
endif

Return .T.

/*/{Protheus.doc} CoCreditos
Consulta creditos não identificados
@author Danilo José Grodzicki
@since 12/03/2020
@version undefined
@param
@type function
/*/
Static Function CoCreditos(cBanco,cAgencia,cConta,dDatIni,dDatFim,cJson)
Local cTab := GetNextAlias()
Local lRet     := .T.

BeginSql Alias cTab
	SELECT ZCG.* 
	  	  ,Z9_TIPO_D
	      ,ZA_NAGE_D
	FROM %TABLE:ZCG% ZCG
	LEFT JOIN SZ9010 SZ9 ON SZ9.Z9_FILIAL = ZCG.ZCG_FILIAL
		AND SZ9.Z9_TIPO = ZCG.ZCG_TIPO
		AND SZ9.D_E_L_E_T_= ''
	LEFT JOIN SZA010 SZA ON SZA.ZA_FILIAL = ZCG.ZCG_FILIAL
		AND SZA.ZA_NAGE = ZCG.ZCG_NAGE
		AND SZA.D_E_L_E_T_= ''	
	WHERE ZCG.ZCG_FILIAL = %xFilial:ZCG%
	  AND ZCG.ZCG_BANCO = %Exp:cBanco%
	  AND ZCG.ZCG_AGENCI = %Exp:cAgencia%
	  AND ZCG.ZCG_CONTA = %Exp:cConta%
	  AND ZCG.ZCG_EMISSA BETWEEN %Exp:dDatIni% AND %Exp:dDatFim%
	  AND ZCG.ZCG_SALDO > 0
	  AND ZCG.%notDel%
EndSql

//cQuery := GETLastQuery()[2]

if (cTab)->(!Eof())
	cJson := '{'
	cJson += '	"creditos": ['
	while (cTab)->(!Eof())
		cJson += '	{'
		cJson += '		"registro": "' + EncodeUTF8(AllTrim((cTab)->ZCG_REGIST), "cp1252") + '",'
		cJson += '		"banco": "' + EncodeUTF8(AllTrim((cTab)->ZCG_BANCO), "cp1252") + '",'
		cJson += '		"agencia": "' + EncodeUTF8(AllTrim((cTab)->ZCG_AGENCI), "cp1252") + '",'
		cJson += '		"conta": "' + EncodeUTF8(AllTrim((cTab)->ZCG_CONTA), "cp1252") + '",'
		cJson += '		"convenio": "' + EncodeUTF8(AllTrim((cTab)->ZCG_CONVEN), "cp1252") + '",'
		cJson += '		"dataemissao": "' + DtoC(StoD((cTab)->ZCG_EMISSA)) + '",'
		cJson += '		"idtipo": "' + EncodeUTF8(AllTrim((cTab)->ZCG_TIPO), "cp1252") + '",'
		cJson += '		"descricaotipo": "' + EncodeUTF8(AllTrim((cTab)->Z9_TIPO_D), "cp1252") + '",'
		cJson += '		"historico": "' + EncodeUTF8(AllTrim((cTab)->ZCG_HIST), "cp1252") + '",'
		cJson += '		"depositante": "' + EncodeUTF8(AllTrim((cTab)->ZCG_DEPOS), "cp1252") + '",'
		cJson += '		"valor": "' + AllTrim(Str((cTab)->ZCG_VALOR,TamSX3("ZCG_VALOR")[1],TamSX3("ZCG_VALOR")[2])) + '",'
		cJson += '		"saldo": "' + AllTrim(Str((cTab)->ZCG_SALDO,TamSX3("ZCG_SALDO")[1],TamSX3("ZCG_SALDO")[2])) + '",'
		cJson += '		"numerodocumento": "' + EncodeUTF8(AllTrim((cTab)->ZCG_NDOC), "cp1252") + '",'
		cJson += '		"numeroagencia": "' + EncodeUTF8(AllTrim((cTab)->ZCG_NAGE), "cp1252") + '",'
		cJson += '		"descricaoagencia": "' + EncodeUTF8(AllTrim((cTab)->ZA_NAGE_D), "cp1252") + '",'
		cJson += '		"unidade": "' + EncodeUTF8(AllTrim((cTab)->ZCG_UNIDAD), "cp1252") + '",'
		cJson += '		"descricaounidade": "' + EncodeUTF8(AllTrim((cTab)->ZCG_DESUNI), "cp1252") + '"'
		cJson += '	}'
		(cTab)->(DbSkip())
		if (cTab)->(!Eof())
			cJson += '	,'
		endif
	enddo
	cJson += '	]'
	cJson += '}'
else
	lRet := .F.
endif

(cTab)->(DbCloseArea())

Return(lRet)

/*/{Protheus.doc} GET
Consulta credito identificado pelo id do movimento
@author carlos.henrique
@since 15/11/2019
@version undefined

@type function
/*/
WSMETHOD GET VISCRD WSRECEIVE idmovimento WSSERVICE CREDITOS
Local cTab := GetNextAlias()
Local cJson:= ""
Local cCnd := " "
Local cIdMOv:= "$%&%$&%"
//Local oJson 

Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""

if ValType(Self:idmovimento) == "C"
	cIdMOv := iif(Empty(Self:idmovimento),cIdMOv,Self:idmovimento)
endif

cCnd += "AND ZCF_NUMMOV='"+ cIdMOv + "'"
cCnd:= "%" + cCnd + "%"

BeginSql Alias cTab
	SELECT * FROM %TABLE:ZCF% ZCF 
	WHERE ZCF_FILIAL=%xfilial:ZCF%
	AND ZCF.D_E_L_E_T_ =''
	AND ZCF_TIPO<>'CRD'		
	%exp:cCnd%
EndSql

TCSETFIELD(cTab,"ZCF_DTMOVI","D")

//aRet:= GETLastQuery()[2]

(cTab)->(dbSelectArea((cTab)))                    
(cTab)->(dbGoTop())                               	
if (cTab)->(!EOF())
	
	cJson+= '{'+CRLF
	cJson+= '   "movimentos":['+CRLF

	WHILE (cTab)->(!EOF())		

		cJson+= '      {'+CRLF
		cJson+= '         "idmovimento":"'+ EncodeUTF8(AllTrim((cTab)->ZCF_NUMMOV)) +'",'+CRLF
		cJson+= '         "data":"'+ EncodeUTF8(DTOC((cTab)->ZCF_DTMOVI)) +'",'+CRLF
		cJson+= '         "registro":"'+ EncodeUTF8(AllTrim((cTab)->ZCF_REGIST)) +'",'+CRLF
		cJson+= '         "prefixotitulo":"'+ EncodeUTF8(AllTrim((cTab)->ZCF_PREFIX)) +'",'+CRLF
		cJson+= '         "numerotitulo":"'+ EncodeUTF8(AllTrim((cTab)->ZCF_NUM)) +'",'+CRLF
		cJson+= '         "parcelatitulo":"'+ EncodeUTF8(AllTrim((cTab)->ZCF_PARCEL)) +'",'+CRLF
		cJson+= '         "tipotitulo":"'+ EncodeUTF8(AllTrim((cTab)->ZCF_TIPO)) +'",'+CRLF
		cJson+= '         "valorCI":"'+ EncodeUTF8(cValToChar((cTab)->ZCF_CI)) +'",'+CRLF
		cJson+= '         "juros":"'+ EncodeUTF8(cValToChar((cTab)->ZCF_JUROS)) +'",'+CRLF
		cJson+= '         "desconto":"'+ EncodeUTF8(cValToChar((cTab)->ZCF_DESCON)) +'",'+CRLF
		cJson+= '         "fechado":"'+ EncodeUTF8(IIF((cTab)->ZCF_FECHAM=="1","1","2")) +'"'+CRLF	
				
		(cTab)->(dbSkip())	

		if (cTab)->(!EOF())
			cJson+= '      },'+CRLF
		else
			cJson+= '      }'+CRLF
		endif	

	END

	cJson+= '   ]'+CRLF
	cJson+= '}'+CRLF

endif

(cTab)->(dbCloseArea())	

If !empty(cJson)
	::SetResponse(cJson)
else
	U_GrvLogKa("CINTK08", "GETCRD", "2", "Nenhum movimento localizado para a condição: " + AllTrim(cCnd) + ".", cJson)
	Return U_RESTERRO(Self,"Nenhum movimento localizado.")
endif		

Return .T.

/*/{Protheus.doc} GET
Consulta de creditos identificados por data
@author carlos.henrique
@since 15/11/2019
@version undefined

@type function
/*/
WSMETHOD GET LSTCRD WSRECEIVE RDRDE,RDRATE,PERIODODE,PERIODOATE WSSERVICE CREDITOS
Local cTab := GetNextAlias()
Local cJson:= ""
Local cCnd := " "
Local cRDRIni:= space(06)
Local cRDRFim:= space(06)
Local dDatIni:= space(08)
Local dDatFim:= space(08)

Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""

if ValType(Self:RDRDE) == "C"
	cRDRIni := Self:RDRDE
endif

if ValType(Self:RDRATE) == "C"
	IF "ZZZ"$Self:RDRATE
		cRDRFim := Self:RDRATE
	ELSE
		cRDRFim := iif(Empty(Self:RDRATE),cRDRFim,Self:RDRATE)
	ENDIF	
endif

if ValType(Self:PERIODODE) == "C"
	dDatIni := iif(Empty(Self:PERIODODE),dDatIni,DtoS(CtoD(Self:PERIODODE)))
endif

if ValType(Self:PERIODOATE) == "C"
	IF "ZZZ"$Self:PERIODOATE
		dDatFim := Self:PERIODOATE
	ELSE
		dDatFim := iif(Empty(Self:PERIODOATE),dDatFim,DtoS(CtoD(Self:PERIODOATE)))
	ENDIF	
endif

cCnd += "AND ZCF_RDR BETWEEN '"+ cRDRIni + "' AND '"+ cRDRFim + "'" 
cCnd += "AND ZCF_DTMOVI BETWEEN '"+ dDatIni + "' AND '"+ dDatFim + "'" 

cCnd:= "%" + cCnd + "%"

BeginSql Alias cTab
	SELECT * FROM %TABLE:ZCF% ZCF 
	WHERE ZCF_FILIAL=%xfilial:ZCF%
	AND ZCF.D_E_L_E_T_ =''
	AND ZCF_TIPO<>'CRD'		
	%exp:cCnd%
EndSql

TCSETFIELD(cTab,"ZCF_DTMOVI","D")

//aRet:= GETLastQuery()[2]

(cTab)->(dbSelectArea((cTab)))                    
(cTab)->(dbGoTop())                               	
if (cTab)->(!EOF())
	
	cJson+= '{'+CRLF
	cJson+= '   "movimentos":['+CRLF

	WHILE (cTab)->(!EOF())		

		cJson+= '      {'+CRLF
		cJson+= '         "idmovimento":"'+ EncodeUTF8(AllTrim((cTab)->ZCF_NUMMOV)) +'",'+CRLF
		cJson+= '         "data":"'+ EncodeUTF8(DTOC((cTab)->ZCF_DTMOVI)) +'",'+CRLF
		cJson+= '         "registro":"'+ EncodeUTF8(AllTrim((cTab)->ZCF_REGIST)) +'",'+CRLF
		cJson+= '         "prefixotitulo":"'+ EncodeUTF8(AllTrim((cTab)->ZCF_PREFIX)) +'",'+CRLF
		cJson+= '         "numerotitulo":"'+ EncodeUTF8(AllTrim((cTab)->ZCF_NUM)) +'",'+CRLF
		cJson+= '         "parcelatitulo":"'+ EncodeUTF8(AllTrim((cTab)->ZCF_PARCEL)) +'",'+CRLF
		cJson+= '         "tipotitulo":"'+ EncodeUTF8(AllTrim((cTab)->ZCF_TIPO)) +'",'+CRLF
		cJson+= '         "valorCI":"'+ EncodeUTF8(cValToChar((cTab)->ZCF_CI)) +'",'+CRLF
		cJson+= '         "juros":"'+ EncodeUTF8(cValToChar((cTab)->ZCF_JUROS)) +'",'+CRLF
		cJson+= '         "desconto":"'+ EncodeUTF8(cValToChar((cTab)->ZCF_DESCON)) +'",'+CRLF
		cJson+= '         "fechado":"'+ EncodeUTF8(IIF((cTab)->ZCF_FECHAM=="1","1","2")) +'"'+CRLF		
				
		(cTab)->(dbSkip())	

		if (cTab)->(!EOF())
			cJson+= '      },'+CRLF
		else
			cJson+= '      }'+CRLF
		endif	

	END

	cJson+= '   ]'+CRLF
	cJson+= '}'+CRLF

endif

(cTab)->(dbCloseArea())	

If !empty(cJson)
	::SetResponse(cJson)
else
	U_GrvLogKa("CINTK08", "GETCRD", "2", "Nenhum movimento localizado para a condição: " + AllTrim(cCnd) + ".", cJson)
	Return U_RESTERRO(Self,"Nenhum movimento localizado.")
endif		

Return .T.

/*/{Protheus.doc} POST
Inclusao de creditos identificados
@author carlos.henrique
@since 15/11/2019
@version undefined

@type function
/*/
WSMETHOD POST GRVCRD WSSERVICE CREDITOS

Local cErro		:= ""
Local cRetorno	:= ""
Local cTipInt	:= "1"

Private oJson  

Private cJson     := ""
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""
Private cIdMovime := ""
Private _cRDR     := SUBSTR(DTOS(DATE()),3,6)

::SetContentType('application/json')

oJson:= JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,cTipInt)
if !Empty(cErro)
	U_GrvLogKa("CINTK08", "GRVCRD", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
endif

// Realiza a gravação na tabela ZCF
cRetorno := GravaZCF(oJson,cTipInt,cJson)

U_GrvLogKa("CINTK08", "GRVCRD", "1", "Integracao realizada com sucesso", cJson, oJson)

::SetResponse(cRetorno)

Return .T.


/*/{Protheus.doc} DELETE
Metodo de exclusao dos creditos reservados
@author carlos.henrique
@since 15/11/2019
@version undefined

@type function
/*/
WSMETHOD DELETE DELCRD WSSERVICE CREDITOS
Local cNumCRD	  := AvKey(::idmovimento,"ZCF_NUMMOV")
Local _cTabMOv    := GetNextAlias()
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""
Private cIdMovime := cNumCRD

dbSelectArea("ZCF")

BeginSql Alias _cTabMOv
	SELECT R_E_C_N_O_ AS RECZCF FROM %TABLE:ZCF% ZCF			 		 	
	WHERE ZCF_FILIAL=%xfilial:ZCF%
		AND ZCF_NUMMOV = %Exp:cNumCRD%
		AND ZCF.D_E_L_E_T_=''	
EndSql

if (_cTabMOv)->(!Eof())
	
	ZCF->(DBGOTO((_cTabMOv)->RECZCF))

	if ZCF->ZCF_FECHAM=="1"
		(_cTabMOv)->(dbCloseArea())
		U_GrvLogKa("CINTK08", "DELCRD", "2", "Movimento "+ cNumCRD +" já foi fechado e não pode ser excluido.")
	 	Return U_RESTERRO(Self,"Movimento "+ cNumCRD +" já foi fechado e não pode ser excluido.")
	endif

	DBSELECTAREA("ZCG")
	ZCG->(DbSetOrder(6))
	if ZCG->(DbSeek(xFilial("ZCG") + ZCF->ZCF_REGIST ))
		RECLOCK("ZCG",.F.)
			ZCG->ZCG_SALDO:= ZCG->ZCG_SALDO + (ZCF->ZCF_CI + ZCF->ZCF_JUROS - ZCF->ZCF_DESCON)	
		MSUNLOCK()				
	endif

	TCSQLEXEC("UPDATE "+RETSQLNAME("ZCH")+ " SET D_E_L_E_T_='*',R_E_C_D_E_L_=R_E_C_N_O_ WHERE ZCH_NUMMOV='"+ZCF->ZCF_NUMMOV+"'")

	RECLOCK("ZCF",.F.)
		ZCF->(DbDelete())
	MSUNLOCK()
	
Else
	(_cTabMOv)->(dbCloseArea())
	U_GrvLogKa("CINTK08", "DELCRD", "2", "Movimento "+ cNumCRD +" não localizado.")
	Return U_RESTERRO(Self,"Movimento "+ cNumCRD +" não localizado.")	
Endif	

(_cTabMOv)->(dbCloseArea())
U_GrvLogKa("CINTK08", "DELCRD", "1", "Identificação de crédito excluida com sucesso")

Return U_RESTOK(self,"Identificação de crédito excluida com sucesso")

/*/{Protheus.doc} ValoJson
Valida os dados do oJson
@author carlos.henrique
@since 15/11/2019
@version undefined

@type function
/*/
Static Function ValoJson(oJson,cTipInt)
Local cRegistro:= AvKey(oJson["credito"]:GetJsonText("registro"),"ZCG_REGISTR")
Local cPrefixo := AvKey(oJson["credito"]:GetJsonText("prefixotitulo"),"E1_PREFIXO")
Local cNumero  := AvKey(oJson["credito"]:GetJsonText("numerotitulo"),"E1_NUM")
Local cParcela := AvKey(oJson["credito"]:GetJsonText("parcelatitulo"),"E1_PARCELA")
Local cTipo    := AvKey(oJson["credito"]:GetJsonText("tipotitulo"),"E1_TIPO")
Local nValorCI := VAL(oJson["credito"]:GetJsonText("valorCI"))
Local nValorJU := VAL(oJson["credito"]:GetJsonText("juros"))
Local nValorDE := VAL(oJson["credito"]:GetJsonText("desconto"))

if Empty(cRegistro)
	Return("O ID do crédito é obrigatorio.")
endif

if Empty(cPrefixo)
	Return("O prefixo do titulo é obrigatorio.")
endif

if Empty(cNumero)
	Return("O numero do titulo é obrigatorio.")
endif

if Empty(cTipo)
	Return("O tipo do titulo é obrigatorio.")
endif

if nValorCI == 0
	Return("O vaor de CI é obrigatorio.")
Endif

//Valida se existe o registro de crédito
DBSELECTAREA("ZCG")
ZCG->(DbSetOrder(6))
if !ZCG->(DbSeek(xFilial("ZCG") + cRegistro ))
	Return("O registro de crédito "+ cRegistro +" não existe.")
endif

DBSELECTAREA("SE1")
SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO 
if !SE1->(DbSeek(xFilial("SE1") + cPrefixo + cNumero + cParcela + cTipo ))
	Return("Titulo não encontrado." + CRLF +;
		   "Prefixo:"+cPrefixo + CRLF +;
		   "Numero:"+cNumero + CRLF +;
		   "Parcela:"+cParcela + CRLF +;
		   "Tipo:"+cTipo)
endif	

IF nValorCI > SE1->E1_SALDO
	Return("A soma do valor de CI não pode ser maior que o valor do titulo."+CRLF+;
			"Saldo:"+CVALTOCHAR(SE1->E1_SALDO))
ENDIF

IF nValorCI + nValorJU - nValorDE > ZCG->ZCG_SALDO
	Return("A soma do valor de CI + Juros - Desconto não pode ser maior que o saldo do crédito."+CRLF+;
			"Saldo:"+CVALTOCHAR(CG->ZCG_SALDO))
ENDIF

Return("")

/*/{Protheus.doc} GravaZCF
Realiza a gravação na tabela de movimentação de caixa
@author carlos.henrique
@since 15/11/2019
@version undefined

@type function
/*/
Static Function GravaZCF(oJson,cTipInt,cJson)
Local cUsrDW3 := TRIM(SuperGetMv("CI_USRDW3",.F.,"000153"))
Local cIdentif := POSICIONE("SZB",3,xFilial("SZB") + cUsrDW3 ,"ZB_IDENT")
Local cDesIdent:= POSICIONE("SZB",3,xFilial("SZB") + cUsrDW3 ,"ZB_IDENT_D")
Local cNumMov  := ""
Local nValorCI := 0
Local nValorJU := 0
Local nValorDE := 0
Local cRetorno := ""
Local cUnidade := ""
Local cDescUni := ""

ZC0->(Dbsetorder(1))
ZC0->(DbSeek(xFilial("ZC0") + SE1->E1_XIDCNT ))

ZC3->(dbSetOrder(2))
If ZC3->(dbSeek(xFilial("ZC3") + SE1->E1_XIDCNT ))
	cUnidade := ZC3->ZC3_UNRESP
Endif

cDescUni:= Posicione("ZCN",1,xFilial("ZCN") + cUnidade ,"ZCN_DLOCAL")

nValorCI:= VAL(oJson["credito"]:GetJsonText("valorCI"))
nValorJU:= VAL(oJson["credito"]:GetJsonText("juros"))
nValorDE:= VAL(oJson["credito"]:GetJsonText("desconto"))


U_CCK06CRD( SE1->E1_XIDCNT )

cNumMov:= GETSXENUM("ZCF","ZCF_NUMMOV")
ConfirmSX8()

RECLOCK("ZCF",.T.)
	ZCF->ZCF_FILIAL:= XFILIAL("ZCF")
	ZCF->ZCF_NUMMOV:= cNumMov
	ZCF->ZCF_DTMOVI:= DATE()
	ZCF->ZCF_UNIDAD:= cUnidade
	ZCF->ZCF_DESUNI:= cDescUni
	ZCF->ZCF_IDENT := cIdentif
	ZCF->ZCF_DIDENT:= cDesIdent
	ZCF->ZCF_FORPGT:= ZC0->ZC0_FORPGT

	if ZC0->ZC0_TIPEMP=="2"
		ZCF->ZCF_RMU:= "U" 	//U = Publica
	elseif ZC0->ZC0_TIPEMP=="1" 
		ZCF->ZCF_RMU:= "R" 	//R = Privada
	elseif ZC0->ZC0_TIPEMP=="3"
		ZCF->ZCF_RMU:= "M"		//M = Mista
	else
		ZCF->ZCF_RMU:= "O"		//O = Outras Contribuicoes						
	endif

	if ZC0->ZC0_TIPCON == "1"
		ZCF->ZCF_TPSERV:= "E" 		//E = Estagio
	elseif ZC0->ZC0_TIPCON == "2"
		ZCF->ZCF_TPSERV:= "AE" 	//AE = Aprendiz Empregador
	else
		ZCF->ZCF_TPSERV:= "OS" 	//OS = Outros Servicos
	endif

	ZCF->ZCF_TIPO	:= SE1->E1_TIPO 	
	ZCF->ZCF_NUM  	:= SE1->E1_NUM 		
	ZCF->ZCF_PREFIX	:= SE1->E1_PREFIXO 	
	ZCF->ZCF_PARCEL	:= SE1->E1_PARCELA 	
	ZCF->ZCF_CLIENT := SE1->E1_CLIENTE 	
	ZCF->ZCF_LOJA  	:= SE1->E1_LOJA 	
	ZCF->ZCF_NOMCLI := SE1->E1_NOMCLI 	
	ZCF->ZCF_EMISSA	:= SE1->E1_EMISSAO 	
	ZCF->ZCF_VENCRE	:= SE1->E1_VENCREA 	
	ZCF->ZCF_VALOR 	:= SE1->E1_VALOR 	
	ZCF->ZCF_SALDO 	:= SE1->E1_SALDO 	
	ZCF->ZCF_CODCTR := SE1->E1_XIDCNT 	
	ZCF->ZCF_LOCCTR	:= SE1->E1_XIDLOC 	
	ZCF->ZCF_COMPET	:= SE1->E1_XCOMPET	
	ZCF->ZCF_IDFOLH	:= SE1->E1_XIDFOLH 	
	ZCF->ZCF_IDFATU	:= SE1->E1_XIDFATU 	 			
	ZCF->ZCF_REGIST := ZCG->ZCG_REGIST
	ZCF->ZCF_CI		:= nValorCI
	ZCF->ZCF_JUROS	:= nValorJU
	ZCF->ZCF_DESCON	:= nValorDE
	ZCF->ZCF_RDR	:= _cRDR
	ZCF->ZCF_DTINTE := Date()
	ZCF->ZCF_HRINTE := Time()
	ZCF->ZCF_JSON   := cJson
MSUNLOCK()

U_CCK06RAT(cNumMov)

RECLOCK("ZCG",.F.)
	ZCG->ZCG_SALDO:= ZCG->ZCG_SALDO - (nValorCI + nValorJU - nValorDE)
MSUNLOCK()				

cRetorno := '{'+CRLF
cRetorno += '	"movimento": {'+CRLF
cRetorno += '		"idmovimento": "' + EncodeUTF8(AllTrim(ZCF->ZCF_NUMMOV)) + '",'+CRLF
cRetorno += '		"rdr": "' + EncodeUTF8(AllTrim(ZCF->ZCF_RDR)) + '"'+CRLF
cRetorno += '	}'+CRLF
cRetorno += '}'+CRLF

cIdMovime := AllTrim(ZCF->ZCF_NUMMOV)

return(cRetorno)
