#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

/*/{Protheus.doc} CINTK11
Integração dos agendamentos
@author danilo.grodzicki
@since 29/06/2020
@version P12.1.25
@type user function
/*/
User Function CINTK11(nRecno)

Local oJson := nil
Local cErro := ""

Private cJson   := ""
Private cTipAge := "1"
Private aAgenda := {}

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK11] Inicio Agendamentos RECNO:" + CVALTOCHAR(nRecno))

DbSelectArea("ZCA")  // Agendamentos
ZCA->(DbSetOrder(01))

DbSelectarea("ZCQ")
ZCQ->(DBGOTO(nRecno))

if !Empty(ZCQ->ZCQ_JSON)
	cJson:= ZCQ->ZCQ_JSON
	oJson := JsonObject():new()
	oJson:fromJson(ZCQ->ZCQ_JSON)   

	// Valida os dados do oJson
	cErro := ValoJson(oJson,cTipAge)
	if !Empty(cErro)
		RECLOCK("ZCQ",.F.)
			ZCQ->ZCQ_STATUS := "1"  // 0 = Pendente; 1 = Erro; 2 = Sucesso
			ZCQ->ZCQ_CODE   := "404"
			ZCQ->ZCQ_MSG    := Alltrim(cErro)
		MSUNLOCK()	
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK13] Fim Agendamentos RECNO:" + CVALTOCHAR(nRecno))
		Return
	endif

	// Realiza a gravação na tabela ZCA
	GravaZCA(oJson,cTipAge,"F")

	RECLOCK("ZCQ",.F.)
		ZCQ->ZCQ_STATUS := "2" 	
		ZCQ->ZCQ_CODE   := "200" // Sucesso
		ZCQ->ZCQ_MSG    := "Agendamento realizado com sucesso"
	MSUNLOCK()	

	FreeObj(oJson)
	
endif

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK13] Fim Agendamentos RECNO:" + CVALTOCHAR(nRecno))

Return

/*/{Protheus.doc} agendamento
Serviço de integração dos agendamentos
@author carlos.henrique
@since 15/11/2019
@version undefined
@type class
/*/
WSRESTFUL AGENDAMENTO DESCRIPTION "Serviço de integração dos agendamentos" FORMAT APPLICATION_JSON
	WSMETHOD POST; 
	DESCRIPTION "Metodo de integração dos agendamentos";
	WSSYNTAX "/AGENDAMENTO"
END WSRESTFUL

/*/{Protheus.doc} POST
Realiza prorrogação da cobrança
@author carlos.henrique
@since 15/11/2019
@version undefined
@type function
/*/
WSMETHOD POST WSSERVICE AGENDAMENTO

Local cErro		:= ""
Private oJson
Private cJson     := ""
Private cTipAge	  := "1"
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""
Private aAgenda   := {}

DbSelectArea("ZCA")  // Agendamentos
ZCA->(DbSetOrder(01))

::SetContentType('application/json')

oJson:= JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,cTipAge)
if !Empty(cErro)
	U_GrvLogKa("CINTK11", "POST", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
endif

// Realiza a gravação na tabela ZCA
GravaZCA(oJson,cTipAge,"R")

U_GrvLogKa("CINTK11", "POST", "1", "Integracao realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Integracao realizada com sucesso")

/*/{Protheus.doc} ValoJson
Valida os dados do oJson
@author carlos.henrique
@since 15/11/2019
@version undefined

@type function
/*/
Static Function ValoJson(oJson,cTipAge)
Local cIdFolha:= ""
Local cTab:= ""
Local nCnta:= 0

DO CASE
	CASE cTipAge == "1" //Bolsa auxílio
	
		For nCnta:=1 to len(oJson["agendamento"]["idsfolha"])
		
			cIdFolha:= oJson["agendamento"]["idsfolha"][nCnta]
			
			IF VALTYPE(cIdFolha)=="N"
				cIdFolha:= CVALTOCHAR(cIdFolha)
			ENDIF
			
			if Empty(cIdFolha) 
				Return("ID da folha é obrigatoria.")
			endif		

			//TODO - Avaliar se já foi concluído a criação da ZC7
			/*
			//Verifica se existe o id de folha
			cTab:= GetNextAlias()
			
			BeginSql Alias cTab
				SELECT * FROM %TABLE:ZC7% ZC7
				WHERE ZC7_FILIAL = %xfilial:ZC7%
				AND ZC7_IDFOL = %Exp:cIdFolha%
				AND ZC7.D_E_L_E_T_ = ''
			EndSql
			
			//	aRet := GETLastQuery()[2]
			(cTab)->(dbSelectArea((cTab)))
			(cTab)->(dbGoTop())
			if (cTab)->(Eof())
				(cTab)->(dbCloseArea())
				Return("O id de folha "+cIdFolha+" não existe.")
			endif
			(cTab)->(dbCloseArea())		
			*/	
			
			//Verifica se já foi processado e não permite novo agendamento
			cTab:= GetNextAlias()
			
			BeginSql Alias cTab
				SELECT * FROM %TABLE:ZCA% ZCA
				WHERE ZCA_FILIAL = %xfilial:ZCA%
				AND ZCA_IDFOL = %Exp:cIdFolha%
				AND ZCA_STATUS='2'
				AND ZCA.D_E_L_E_T_ = ''
			EndSql
			
			//	aRet := GETLastQuery()[2]
			(cTab)->(dbSelectArea((cTab)))
			(cTab)->(dbGoTop())
			if (cTab)->(!Eof())
				(cTab)->(dbCloseArea())
				Return("O pagamento da folha "+cIdFolha+" já foi processado")
			endif
			(cTab)->(dbCloseArea())					
		Next
	
		if Empty(oJson["agendamento"]:GetJsonText("datapagamento")) 
			Return("Data de pagamento da folha é obrigatoria.")
		endif		

		if Empty(oJson["agendamento"]:GetJsonText("datapagamento")) 
			Return("Data de pagamento da folha é obrigatoria.")
		endif
						
ENDCASE

Return("")
/*/{Protheus.doc} GravaZCA
Realiza a gravação na tabela ZCA
@author carlos.henrique
@since 15/11/2019
@version undefined

@type function
/*/
Static Function GravaZCA(oJson,cTipAge,cTipoFila)
Local cRevisa:= ""
Local cTab:= ""
Local nCnta:= 0

DO CASE
	CASE cTipAge == "1" //Bolsa auxílio
	
	dDtaPag := CTOD(oJson["agendamento"]:GetJsonText("datapagamento"))
	cMotPag := oJson["agendamento"]:GetJsonText("motivoalteracao")
	
	For nCnta:=1 to len(oJson["agendamento"]["idsfolha"])
		cRevisa := "00"
		cIdFolha:= oJson["agendamento"]["idsfolha"][nCnta]

		IF VALTYPE(cIdFolha)=="N"
			cIdFolha:= CVALTOCHAR(cIdFolha)
		ENDIF
		
		cTab:= GetNextAlias()
		
		BeginSql Alias cTab
			SELECT MAX(ZCA_REVISA) as REVISAO FROM %TABLE:ZCA% ZCA
			WHERE ZCA_FILIAL = %xfilial:ZCA%
			AND ZCA_IDFOL = %Exp:cIdFolha%
			AND ZCA.D_E_L_E_T_ = ''
		EndSql
		
		//	aRet := GETLastQuery()[2]
		(cTab)->(dbSelectArea((cTab)))
		(cTab)->(dbGoTop())
		if (cTab)->(!Eof())
			cRevisa:= (cTab)->REVISAO
		endif
		(cTab)->(dbCloseArea())
		
		cRevisa:= SOMA1(cRevisa)
		
		RecLock("ZCA",.T.)
			ZCA->ZCA_FILIAL := xFilial("ZCA")
			ZCA->ZCA_IDFOL 	:= cIdFolha
			ZCA->ZCA_DTAPAG := dDtaPag
			ZCA->ZCA_MOTALT := cMotPag
			ZCA->ZCA_REVISA := cRevisa			
			ZCA->ZCA_DTINTE := Date()
			ZCA->ZCA_HRINTE := Time()
			ZCA->ZCA_JSON   := cJson
			ZCA->ZCA_STATUS := "1" // Aguardando processamento
		ZCA->(MsUnLock())

		if cTipoFila = "R"  // REST
			// Utilizado na função GrvLogKa do fonte CINTK01
			aadd(aAgenda,{ZCA->ZCA_IDFOL, ZCA->ZCA_REVISA, ZCA->ZCA_DTINTE, ZCA->ZCA_HRINTE})
		endif

	Next
ENDCASE		

Return Nil