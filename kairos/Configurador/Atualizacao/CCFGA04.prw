#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCFGA04
Manutenção de grupos de aprovação RH e integração com Fluig
@author  	Carlos Henrique
@since     	28/07/2017
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function CCFGA04()    
	Local oBrowse := FwMBrowse():New()

	oBrowse:SetAlias("ZAH")
	oBrowse:SetDescription("Grupos de aprovação RH") 
	oBrowse:DisableDetails() 

	// Ativação da Classe
	oBrowse:Activate()						

RETURN
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina de definição do menu
@author  	Carlos Henrique
@since     	28/07/2017
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function MenuDef()
	Local aRotinc := {}
	Local aRotina := {}

	ADD OPTION aRotinc TITLE "Incluir" ACTION "VIEWDEF.CCFGA04" OPERATION 3	ACCESS 0 
	ADD OPTION aRotinc TITLE "Gerar Grupos Hierarquia" ACTION "U_CCA04PRO(1)" OPERATION 3	ACCESS 0 
	ADD OPTION aRotina TITLE "Pesquisar" ACTION "AxPesqui" OPERATION 1	ACCESS 0 		
	ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.CCFGA04" OPERATION 2 ACCESS 0 		
	ADD OPTION aRotina TITLE "Incluir" ACTION aRotinc OPERATION 3	ACCESS 0 		
	ADD OPTION aRotina TITLE "Alterar" ACTION "VIEWDEF.CCFGA04" OPERATION 4	ACCESS 0
	ADD OPTION aRotina TITLE "Excluir" ACTION "VIEWDEF.CCFGA04" OPERATION 5	ACCESS 0
//	ADD OPTION aRotina TITLE "Integração Fluig" ACTION "U_CCA04PRO(2)" OPERATION 6 ACCESS 0

Return(aRotina)
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina de definição do MODEL
@author  	Carlos Henrique
@since     	28/07/2017
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function ModelDef()
	Local oStruCAB 	:= FWFormStruct(1, "ZAH", {|cCpo| ALLTRIM(cCpo)$"ZAH_CODIGO,ZAH_CC,ZAH_DESCRI,ZAH_TIPO" })  
	Local oStruITENS	:= FWFormStruct(1, "ZAH", {|cCpo| !ALLTRIM(cCpo)$"ZAH_CODIGO,ZAH_CC,ZAH_DESCRI,ZAH_TIPO" } )
	Local bCommit		:= {|oModel| CCA04GRV(oModel)}
	Local oModel   	:= MPFormModel():New( 'CCA04MD', /*bPreValidacao*/, /*bPosVld*/, bCommit , /*bCancel*/ )

	oModel:AddFields("ZAHMASTER", /*cOwner*/, oStruCAB)

	oModel:AddGrid("ZAHDETAIL", "ZAHMASTER", oStruITENS)
	oModel:SetPrimaryKey({"ZAH_FILIAL","ZAH_CODIGO"})
	oModel:SetRelation("ZAHDETAIL", {{'ZAH_FILIAL', 'xFilial("ZAH")'}, {"ZAH_CODIGO", "ZAH_CODIGO"}, {"ZAH_TIPO", "ZAH_TIPO"}}, ZAH->(IndexKey(1)))
	oModel:SetDescription("Grupos de aprovação RH")

Return oModel
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina de definição do VIEW
@author  	Carlos Henrique
@since     	28/07/2017
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function ViewDef()
	Local oView    	:= FWFormView():New()
	Local oStruCAB 	:= FWFormStruct( 2, "ZAH", {|cCpo| ALLTRIM(cCpo)$"ZAH_CODIGO,ZAH_CC,ZAH_DESCRI,ZAH_TIPO" })  
	Local oStruITENS	:= FWFormStruct( 2, "ZAH", {|cCpo| !ALLTRIM(cCpo)$"ZAH_CODIGO,ZAH_CC,ZAH_DESCRI,ZAH_TIPO" } )  
	Local oModel   	:= FWLoadModel("CCFGA04")           	

	oView:SetModel(oModel)
	oView:AddField("VIEW_CAB", oStruCAB, "ZAHMASTER")
	oView:AddGrid("VIEW_ITENS", oStruITENS, "ZAHDETAIL")

	oView:CreateHorizontalBox("SUPERIOR", 30)
	oView:CreateHorizontalBox("INFERIOR", 70)

	oView:SetOwnerView("VIEW_CAB", "SUPERIOR")
	oView:SetOwnerView("VIEW_ITENS", "INFERIOR")

Return oView
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCA04GRV
Realiza a atualização do campo ZAH_TIPO antes da gravação
@author  	Carlos Henrique
@since     	28/07/2017
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
STATIC Function CCA04GRV(oModel)
	Local lRet 		:= .T. 
	Local oMdlMaster	:= oModel:GetModel("ZAHMASTER")
//	Local oMdlDet		:= oModel:GetModel("ZAHDETAIL")
	Local cTipo		:= oMdlMaster:Getvalue("ZAH_TIPO")
	Local cChave		:= XFILIAL("ZAH")+oMdlMaster:Getvalue("ZAH_CODIGO")
//	Local nCnt			:= 0

	lRet := FWFormCommit(oModel)

	//Atualiza os campos status e tipo para todas as linhas
	IF lRet .AND. oModel:nOperation== MODEL_OPERATION_UPDATE
		DBSELECTAREA("ZAH")
		ZAH->(DBSETORDER(1))
		WHILE ZAH->(!EOF()) .AND. ZAH->(ZAH_FILIAL+ZAH_CODIGO) == cChave
			if Empty(ZAH->ZAH_TIPO)
				RECLOCK("ZAH",.F.)
				ZAH->ZAH_TIPO		:= cTipo
				ZAH->(MSUNLOCK())
			endif
			ZAH->(DBSKIP())
		END
	Endif

RETURN lRet
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCA04PRO
Monta regua de processamento de acordo com a opção seleciona no menu de opções
@author  	Carlos Henrique
@since     	28/07/2017
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
USER FUNCTION CCA04PRO(nOpc, lJob)
//Local cCodReg	:= AllTrim(GetNewPar("CI_IDPREN","PRENOT"))
Local aParam	:= {}
Local aParRet	:= {}	
Default lJob 	:= .F.

IF nOpc == 1

	aAdd(aParam,{1,"Regra",Space(FwTamSX3("ZAI_REGRA")[1]),"","","ZX","",0,.T.}) 

	IF ParamBox(aParam,"Informe a regra de alçadas",@aParRet)
	 	IF MSGYESNO("Confirma a geração dos grupos de aprovação regra " + AllTrim(aParRet[1]) + " de acordo com a Hierarquia do RH ?")
	 		if AllTrim(aParRet[1]) == "FFQ" .OR.; 
	 			AllTrim(aParRet[1]) == "FOLPAG" .OR.;
	 				AllTrim(aParRet[1]) == "SERDIR" .OR.;
	 				AllTrim(aParRet[1]) == "REQMAT" .OR.;
	 				AllTrim(aParRet[1]) == "BOLAUX"
	 			Processa( {|| CCA04GEFFQ(.F.,aParRet[1]) },, "Realizando geração dos grupos de aprovação de acordo com a Hierarquia do RH, aguarde...",.F.)
	 		else
	 			Processa( {|| CCA04GER(.F.,aParRet[1]) },, "Realizando geração dos grupos de aprovação de acordo com a Hierarquia do RH, aguarde...",.F.)
	 		endif
	 	ENDIF	
	ENDIF
	
ElseIF nOpc == 2 
	If !lJob
		IF MSGYESNO("Confirma a integração dos Grupos de aprovação com Fluig ?")
			Processa( {|| CCA04INT("H", lJob) },, "Realizando integração com Fluig, aguarde...",.F.)
		EndIf
	Else
		Processa( {|| CCA04INT("H", lJob) },, "Realizando integração com Fluig, aguarde...",.F.)
	EndIF
ElseIF nOpc == 3 .and. MSGYESNO("Confirma a integração dos Grupos de aprovação do tipo Procuradores com Fluig ?")
	Processa( {|| CCA04INT("P") },, "Realizando integração com Fluig, aguarde...",.F.)
ENDIF

RETURN
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCA04GER
Realizando geração dos grupos de aprovação de acordo com a Hierarquia do RH
@author  	Carlos Henrique
@since     	28/07/2017
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
STATIC FUNCTION CCA04GER(lJob,cCodReg)
	
//	Local cArqTRB
	Local cMatSup
	Local cNivelAtu
	Local cAliasTmp
	
	Local nCargo    := 0
	Local aStruTRB  := {}
//	Local cInd1TRB  := ""
//	Local cInd2TRB  := ""
	Local cTab		:= GetNextAlias()
	Local cCodGrp	:= ""
	Local cCCusto	:= ""
	Local cDesGrp	:= ""
	Local cNivel	:= ""
	local lTemGrp	:= .F.
	Local aGrupos	:= {}
	Local nPosCod	:= 0
	Local nCntGrp	:= 0
	Local nTotGrp	:= 0
	Local aVlrAlc	:= {STRTOKARR(AllTrim(GetNewPar("CI_VLRNIV0","0|0")),"|"),;  // Valores para nivel Colaborador             Cargo = 0
	STRTOKARR(AllTrim(GetNewPar("CI_VLRNIV1","0|0")),"|"),;                      // Valores para nivel Secretária              Cargo = 1
	STRTOKARR(AllTrim(GetNewPar("CI_VLRNIV2","0|999999999.99")),"|"),;           // Valores para nivel Supervisor              Cargo = 2
	STRTOKARR(AllTrim(GetNewPar("CI_VLRNIV3","3000.01|999999999.99")),"|"),;     // Valores para nivel Gerência                Cargo = 3
	STRTOKARR(AllTrim(GetNewPar("CI_VLRNIV4","10000.01|999999999.99")),"|"),;    // Valores para nivel Superintendência        Cargo = 4
	STRTOKARR(AllTrim(GetNewPar("CI_VLRNIV5","30000.01|999999999.99")),"|"),;    // Valores para nivel Superintendência Geral  Cargo = 5
	STRTOKARR(AllTrim(GetNewPar("CI_VLRNIV6","3000.01|999999999.99")),"|")}      // Valores para nivel Gerência Específica     Cargo = 3 e centro de custo estar no parâmetro CI_GERESPE 
	Local cDesReg	:= POSICIONE("SX5",1,XFILIAL("SX5")+"ZX"+cCodReg,"X5_DESCRI")
	Local lTemSuper := .F.
	Local cCodigoZah := ""
	Local lTemGerEsp := .F.
//	Local cMatAprFFQ
//	Local cTabGrp
//	Local cTabZai
//	Local cTabPad
//	Local cMatSupPad
//	Local cGrpSupPad
//	Local cGrpAprFFQ
//	Local cTabNivel
	Local cZAA 		:= ZAA->(DbSeek(xFilial("ZAA")+GetMv("CI_MATSUPE",.F.,"")))
	Local cParGer	:= GetMv("CI_GERESPE",.F.,"")
	DEFAULT lJob	:= .F.
	
	Private aMatricula := {}
	
	aStruTRB := {{ "NIVEL"     , "C" , FwTamSX3("ZAH_NIVEL")[1]  , 0 },;
	             { "MATRIC"    , "C" , FwTamSX3("ZAA_MAT")[1]    , 0 },;
	             { "NOME"      , "C" , FwTamSX3("ZAA_NOME")[1]   , 0 },;
	             { "LGREDE"    , "C" , FwTamSX3("ZAA_LGREDE")[1] , 0 },;
	             { "CCUSTO"    , "C" , FwTamSX3("ZAA_CC")[1]     , 0 },;
	             { "CTD_DESC01", "C" , FwTamSX3("CTD_DESC01")[1] , 0 },;
	             { "MATSUP"    , "C" , FwTamSX3("ZAA_MATSUP")[1] , 0 },;
	             { "CCSUP"     , "C" , FwTamSX3("ZAA_CC")[1]     , 0 },;
	             { "CARGO"     , "C" , FwTamSX3("ZAA_CARGO")[1]  , 0 },;
	             { "CODHIE"    , "C" , FwTamSX3("ZAA_CODHIE")[1] , 0 } }
	
	U_uCriaTrab("TRB",aStruTRB,{ {"NIVEL","MATRIC"}})

	TRB->(DbSetOrder(1))
	
	DbSelectArea("ZAA")
	ZAA->(DbSetOrder(01))
	
	DbSelectArea("CTD")
	CTD->(DbSetOrder(01))
	
	BEGIN TRANSACTION

		//Apaga todos as regras de aprovação do tipo pre nota para gerar novamente
		IF TCSQLEXEC("DELETE "+RETSQLNAME("ZAI")+" WHERE ZAI_FILIAL='"+XFILIAL("ZAI")+"' AND ZAI_REGRA='"+cCodReg+"' AND ZAI_PADRAO = 'T' AND D_E_L_E_T_=''") < 0
			MSGALERT(TCSQLERROR())
			DisarmTransaction()
			BREAK
		ENDIF

		//Se o código grupo de aprovação do centro de custo já foi gerado antes, mantem o mesmo... 
		BeginSQL Alias cTab
		SELECT * FROM %TABLE:ZAA% ZAA
		WHERE ZAA_FILIAL=%XFILIAL:ZAA%
		AND ZAA.D_E_L_E_T_='' 
		ENDSQL

		//GETLastQuery()[2]		 

		(cTab)->(dbSelectArea((cTab)))

		(cTab)->(dbGoTop())                               	
		While (cTab)->(!Eof())	
			//Gera regra de aprovação pré nota
			RECLOCK("ZAI",.T.)
			ZAI->ZAI_FILIAL	:= XFILIAL("ZAI")
			ZAI->ZAI_REGRA	:= cCodReg
			ZAI->ZAI_DESC	:= cDesReg
			ZAI->ZAI_MAT	:= (cTab)->ZAA_MAT
			ZAI->ZAI_MATSUP	:= (cTab)->ZAA_MATSUP	
			ZAI->ZAI_PADRAO := .T.		
			ZAI->ZAI_TIPO   := "H"	
			MSUNLOCK() 
			(cTab)->(dbSkip())	
		End  
		(cTab)->(dbCloseArea())

		//Se o código grupo de aprovação do centro de custo já foi gerado antes, mantem o mesmo... 
		BeginSQL Alias cTab
		SELECT ZAH_CC,ZAH_MAT,ZAH_CODIGO FROM %TABLE:ZAH% ZAH
		WHERE ZAH_FILIAL=%XFILIAL:ZAH%
		AND ZAH_NIVEL='01'
		AND ZAH_TIPO='H'
		AND ZAH.D_E_L_E_T_='' 
		GROUP BY ZAH_CC,ZAH_MAT,ZAH_CODIGO
		ORDER BY ZAH_CODIGO
		ENDSQL

		//GETLastQuery()[2]		 

		(cTab)->(dbSelectArea((cTab)))

		(cTab)->(dbGoTop())                               	
		While (cTab)->(!Eof())	
			IF ASCAN(aGrupos,{|x| TRIM(x[1]) == TRIM((cTab)->ZAH_CC) .AND. TRIM(x[2]) == TRIM((cTab)->ZAH_MAT) }) == 0
				AADD(aGrupos,{(cTab)->ZAH_CC,(cTab)->ZAH_MAT,(cTab)->ZAH_CODIGO})
			ENDIF	
			(cTab)->(dbSkip())	
		End  
		(cTab)->(dbCloseArea()) 	
		
		//Apaga todos os grupos de aprovação do tipo gestores para gerar novamente
		IF TCSQLEXEC("DELETE "+RETSQLNAME("ZAH")+" WHERE ZAH_FILIAL='"+XFILIAL("ZAH")+"' AND ZAH_TIPO='H' AND D_E_L_E_T_=''") < 0
			MSGALERT(TCSQLERROR())
			DisarmTransaction()
			BREAK
		ENDIF
		
		DBSELECTAREA("ZAH")
		ZAH->(DBSETORDER(2))
		
		//Seleciona todos os superiores cadastro de matriculas do RH
		BeginSQL Alias cTab
		SELECT ZAA.ZAA_MATSUP FROM %TABLE:ZAA% ZAA
		INNER JOIN %TABLE:ZAA% ZAAB ON ZAAB.ZAA_FILIAL=%XFILIAL:ZAA% 
		AND ZAAB.ZAA_MAT=ZAA.ZAA_MATSUP
		AND ZAAB.D_E_L_E_T_=''
		WHERE ZAA.ZAA_FILIAL=%XFILIAL:ZAA% 
		AND ZAA.ZAA_MATSUP!=''
		AND ZAA.D_E_L_E_T_='' 
		GROUP BY ZAA.ZAA_MATSUP
		UNION ALL
		SELECT DISTINCT ZAA.ZAA_MAT
		FROM %TABLE:ZAA% ZAA
		WHERE NOT EXISTS(SELECT DISTINCT ZAH.ZAH_MAT FROM %TABLE:ZAH% ZAH WHERE ZAH.ZAH_FILIAL=%XFILIAL:ZAH% AND ZAH.ZAH_MAT = ZAA.ZAA_MAT AND ZAH.D_E_L_E_T_ = ' ')
		AND ZAA.ZAA_CARGO NOT IN('0','1','5')
		AND ZAA.D_E_L_E_T_ = ' '
		ENDSQL

		//GETLastQuery()[2]		 

		(cTab)->(dbSelectArea((cTab)))

		COUNT TO nTotGrp

		IF !lJob
			ProcRegua(nTotGrp)
		ENDIF

		(cTab)->(dbGoTop())                               	
		While (cTab)->(!Eof())
				
			nCntGrp++
			IncProc("Processando grupo de aprovação "+ cvaltochar(nCntGrp) + " de " + cvaltochar(nTotGrp) + "." )		
/*
			cTSup:= GetNextAlias()
			//Monta grupo de aprovação de acordo com a Hierarquia do RH para a matricula informada por parametro 
			BeginSQL Alias cTSup
			%NOPARSER%
			WITH ESTRH(NIVEL,MATRIC,MATSUP,NOME,LGREDE,CCUSTO,CARGO,CODHIE)
			AS(	SELECT 1 AS NIVEL
			,ZAA_MAT AS MATRIC
			,ZAA_MATSUP AS MATSUP
			,ZAA_NOME AS NOME
			,ZAA_LGREDE AS LGREDE
			,ZAA_CC AS CCUSTO
			,ZAA_CARGO AS CARGO 
			,ZAA_CODHIE AS CODHIE
			FROM %TABLE:ZAA% ZAAX
			WHERE ZAAX.ZAA_FILIAL=%XFILIAL:ZAA%
			AND ZAAX.ZAA_MAT=%EXP:(cTab)->ZAA_MATSUP% 	
			AND ZAAX.D_E_L_E_T_=''
			UNION ALL
			SELECT EST.NIVEL+1 AS NIVEL
			,ZAA_MAT AS MATRIC
			,ZAA_MATSUP AS MATSUP
			,ZAA_NOME AS NOME
			,ZAA_LGREDE AS LGREDE
			,ZAA_CC AS CCUSTO 
			,ZAA_CARGO AS CARGO
			,ZAA_CODHIE AS CODHIE
			FROM %TABLE:ZAA% ZAAY
			INNER JOIN ESTRH EST ON EST.MATSUP=ZAAY.ZAA_MAT
			WHERE ZAAY.ZAA_FILIAL=%XFILIAL:ZAA%
			AND ZAAY.D_E_L_E_T_=''
			)
			SELECT NIVEL
			,MATRIC
			,NOME
			,LGREDE
			,CCUSTO
			,COALESCE(CTD_DESC01, 'GRUPO DE APROVAÇÃO '+ CCUSTO) AS CTD_DESC01
			,MATSUP
			,ZAA_CC AS CCSUP
			,CARGO
			,CODHIE 
			FROM ESTRH
			LEFT JOIN %TABLE:CTD% CTD ON CTD_FILIAL=%XFILIAL:CTD% 
			AND CTD_ITEM=ESTRH.CCUSTO
			AND CTD.D_E_L_E_T_=' ' 	
			LEFT JOIN %TABLE:ZAA% ZAAZ ON ZAA_FILIAL=%XFILIAL:ZAA% 
			AND ZAA_MAT=ESTRH.MATSUP
			AND ZAAZ.D_E_L_E_T_=' ' 
			WHERE NIVEL<=2		
			ORDER BY NIVEL	
			ENDSQL
			//GETLastQuery()[2]
*/
			
//			DbSelectArea("TRB")
//			ZAP
			U_uCriaTrab("TRB",aStruTRB,{ {"NIVEL","MATRIC"}})
			TRB->(DbSetOrder(1))
			if ZAA->(DbSeek(xFilial("ZAA")+(cTab)->ZAA_MATSUP))
				
				// Não irá gerar grupo de aprovação caso a matrícula seja igual a matrícula superior
				if AllTrim(ZAA->ZAA_MAT) == AllTrim(ZAA->ZAA_MATSUP)
					
					// Armazena em matriz para envio de e-mail
					aadd(aMatricula,{ZAA->ZAA_MAT,ZAA->ZAA_NOME})
					
					(cTab)->(dbSkip())
					loop
						
				endif
				
				nNivel     := 1
				cMatricula := ZAA->ZAA_MAT
				while ZAA->(!Eof()) .and. (AllTrim(ZAA->ZAA_MATSUP) <> "00" .or. AllTrim((cTab)->ZAA_MATSUP) == "79747" .and. nNivel == 1)
					if ZAA->(DbSeek(xFilial("ZAA")+cMatricula))
						if TRB->(!Eof())
							If RecLock("TRB",.F.)
								TRB->CCSUP := ZAA->ZAA_CC
								TRB->(MsUnlock())
							endif
						endif
						If RecLock("TRB",.T.)
							TRB->NIVEL  := StrZero(nNivel,2)
							TRB->MATRIC := ZAA->ZAA_MAT
							TRB->NOME   := ZAA->ZAA_NOME
							TRB->LGREDE := ZAA->ZAA_LGREDE
							TRB->CCUSTO := ZAA->ZAA_CC
							if CTD->(DbSeek(xFilial("CTD")+ZAA->ZAA_CC))
								TRB->CTD_DESC01 := CTD->CTD_DESC01
							else
								TRB->CTD_DESC01 := "GRUPO DE APROVAÇÃO " + AllTrim(ZAA->ZAA_CC)
							endif
							TRB->MATSUP := ZAA->ZAA_MATSUP
							TRB->CARGO  := ZAA->ZAA_CARGO
							TRB->CODHIE := ZAA->ZAA_CODHIE
							TRB->(MsUnlock())
						endif
						nNivel     += 1
						cMatricula := ZAA->ZAA_MATSUP
					endif
				enddo
				
				if TRB->(Eof())
					(cTab)->(dbSkip())
					loop	
				endif
				
				// Verifica se existe o nível Superintendência
				if AllTrim((cTab)->ZAA_MATSUP) <> "79747"
					lTemSuper := .F.
					TRB->(DbGoTop())
					while TRB->(!Eof())
						if TRB->CARGO == "4" .and. TRB->MATSUP <> "00    "
							lTemSuper := .T.
							exit
						endif
						TRB->(DbSkip())
					enddo
				endif
				
				// Não tem o nível Superintendência, inclui o padrão
				if !lTemSuper
					if cZAA
						If RecLock("TRB",.T.)
							TRB->NIVEL  := "99"
							TRB->MATRIC := ZAA->ZAA_MAT
							TRB->NOME   := ZAA->ZAA_NOME
							TRB->LGREDE := ZAA->ZAA_LGREDE
							TRB->CCUSTO := ZAA->ZAA_CC
							if CTD->(DbSeek(xFilial("CTD")+ZAA->ZAA_CC))
								TRB->CTD_DESC01 := CTD->CTD_DESC01
							else
								TRB->CTD_DESC01 := "GRUPO DE APROVAÇÃO " + AllTrim(ZAA->ZAA_CC)
							endif
							TRB->MATSUP := ZAA->ZAA_MATSUP
							TRB->CARGO  := ZAA->ZAA_CARGO
							TRB->CODHIE := ZAA->ZAA_CODHIE
							TRB->(MsUnlock())
						endif
					endif
					TRB->(DbSkip(-1))
					If RecLock("TRB",.F.)
						TRB->NIVEL := StrZero(Val(TRB->NIVEL) + 1,2)
						TRB->(MsUnlock())
					endif
					cNivelAtu := StrZero(Val(TRB->NIVEL) - 1,2)
					TRB->(DbGoBottom())
					If RecLock("TRB",.F.)
						TRB->NIVEL := cNivelAtu
						TRB->(MsUnlock())
					endif
					
					// Ajustar a matrícula superior do nível 02
					cMatSup := TRB->MATRIC  // pego a matrícula do nível 03
					TRB->(DbSkip(-1))
					If RecLock("TRB",.F.)
						TRB->MATSUP := cMatSup
						TRB->(MsUnlock())
					endif
				endif
				
			else
				(cTab)->(dbSkip())
				loop	
			endif
			
			TRB->(DbGoTop())
			if TRB->(!Eof())
				
				cCodGrp := ""
				cCCusto := ""
				
				While TRB->(!Eof())
					
					cNivel := TRB->NIVEL
					
					if TRB->NIVEL == "01"
						lTemGrp := .F.		
						if ZAH->(DbSeek(XFilial("ZAH")+TRB->MATRIC+cNivel))
							while XFilial("ZAH")+TRB->MATRIC+cNivel == ZAH->ZAH_FILIAL+ZAH->ZAH_MAT+ZAH->ZAH_NIVEL .and. ZAH->(!Eof())
								if ZAH->ZAH_TIPO == "H"
									exit
								endif
								ZAH->(DbSkip())
							enddo
							if XFilial("ZAH")+TRB->MATRIC+cNivel+"H" == ZAH->ZAH_FILIAL+ZAH->ZAH_MAT+ZAH->ZAH_NIVEL+ZAH->ZAH_TIPO .and. ZAH->(!Eof())
								cCodGrp := ZAH->ZAH_CODIGO
								cCCusto := ZAH->ZAH_CC
								lTemGrp := .T.
							endif
						endif
						
						if !lTemGrp
							//Verifica se o código do grupo de aprovação já existe
							if (nPosCod := ASCAN(aGrupos,{|x| TRIM(x[1])== TRIM(TRB->CCUSTO) .and. TRIM(x[2]) == TRIM(TRB->MATRIC) })) == 0
								cCodGrp := CCA04NUM("H") //GETSX8NUM("ZAH","ZAH_CODIGO")
								//ZAH->(ConfirmSX8())	
							else
								cCodGrp := aGrupos[nPosCod][3]
							endif
							cCCusto := TRB->CCUSTO
							cDesGrp := TRB->CTD_DESC01
						endif
						
						//Atualiza campo do grupo de aprovação Gestores do FLUIG na tabela ZAA
						IF TCSQLEXEC("UPDATE "+RETSQLNAME("ZAA")+" SET ZAA_GRPFLG='H"+cCodGrp+"' WHERE ZAA_MATSUP='"+(cTab)->ZAA_MATSUP+"' AND D_E_L_E_T_=''") < 0
							U_uCONOUT(TCSQLERROR())
						ENDIF
						
						//Atualiza campo do grupo de aprovação Gestores do FLUIG na tabela ZAA					
						IF TCSQLEXEC("UPDATE "+RETSQLNAME("ZAI")+" SET ZAI_GRUPO='"+cCodGrp+"' WHERE ZAI_REGRA='"+cCodReg+"' AND ZAI_MATSUP='"+(cTab)->ZAA_MATSUP+"' AND ZAI_PADRAO = 'T' AND D_E_L_E_T_=''") < 0
							U_uCONOUT(TCSQLERROR())
							MSGALERT(TCSQLERROR())
							DisarmTransaction()
							BREAK
						ENDIF
						
						//Caso o código do grupo não esteja preenchido não grava 
						IF lTemGrp
							TRB->(DbSkip())
							loop	// Se ja possui grupo pula para a próxima matricula
						ENDIF
					ENDIF
					
					cAliasTmp := GetNextAlias()
					
					BeginSQL Alias cAliasTmp
						%NOPARSER%
						SELECT ZAH.ZAH_CODIGO
						FROM %TABLE:ZAH% ZAH
						WHERE ZAH.D_E_L_E_T_ <> '*'
						  AND ZAH.ZAH_FILIAL = %XFILIAL:ZAH%
						  AND ZAH.ZAH_CODIGO = %EXP:cCodGrp%
						  AND ZAH.ZAH_MAT = %EXP:TRB->MATRIC%
					ENDSQL
					(cAliasTmp)->(DbGoTop())
					if (cAliasTmp)->(Eof())
						RECLOCK("ZAH",.T.)
						ZAH->ZAH_FILIAL := XFILIAL("ZAH")
						ZAH->ZAH_CODIGO := cCodGrp
						ZAH->ZAH_CC	    := cCCusto
						ZAH->ZAH_DESCRI := cDesGrp
						ZAH->ZAH_TIPO	:= "H"   // Gestores
						ZAH->ZAH_MAT	:= TRB->MATRIC
						ZAH->ZAH_LGREDE := TRB->LGREDE
						ZAH->ZAH_NOME   := TRB->NOME
						ZAH->ZAH_MATSUP := TRB->MATSUP
						ZAH->ZAH_NIVEL  := cNivel
						MSUNLOCK()
					endif
					(cAliasTmp)->( dbCloseArea() )
					
					TRB->(DbSkip())
				enddo
				
				IF lTemGrp  // se tem grupo, verifico se a matrícula do ZAH tem no TRB.
					DBSELECTAREA("ZAH")
					ZAH->(DBSETORDER(1))
					DbSelectArea("TRB")
					TRB->(DbSetOrder(2))
					if ZAH->(DbSeek(xFilial("ZAH")+cCodGrp))
						while ZAH->ZAH_CODIGO == cCodGrp .and. ZAH->(!Eof())
							if !TRB->(DbSeek(ZAH->ZAH_MAT))
								If RecLock("ZAH",.F.)
									ZAH->(DbDelete())
									ZAH->(MsUnlock())
								endif
							endif
							ZAH->(DbSkip())
						enddo
					endif
					DbSelectArea("TRB")
					TRB->(DbSetOrder(1))
					DBSELECTAREA("ZAH")
					ZAH->(DBSETORDER(2))
				ENDIF
				
			endif
			
			(cTab)->(dbSkip())	
		Enddo  
		(cTab)->(dbCloseArea())
		
		//Atualiza os valores minimo e maximo de aprovação
		DBSELECTAREA("ZAH")
		ZAH->(DBGOTOP())	
		
		cTab:= GetNextAlias()
		BeginSQL Alias cTab
		SELECT ZAH.R_E_C_N_O_ AS RECZAH,
		       ZAA.ZAA_CARGO AS CARGO,
		       ZAA.ZAA_CC AS CENTROCUST,
		       ZAA.ZAA_CODHIE AS CODHIE,
		       ZAH_CODIGO AS CODIGOZAH,
		       ZAH_NIVEL AS NIVEL
		FROM %TABLE:ZAH% ZAH
		INNER JOIN %TABLE:ZAA% ZAA ON ZAA_FILIAL = %XFILIAL:ZAA% 
		AND ZAA_MAT = ZAH_MAT
		AND ZAA.D_E_L_E_T_ = ' ' 		
		WHERE ZAH_FILIAL = %XFILIAL:ZAH%
		AND ZAH_TIPO = 'H'
		AND ZAH.D_E_L_E_T_ = '' 
		ORDER BY ZAH_CODIGO, ZAH_NIVEL
		ENDSQL
		
		cCodigoZah := ""
		lTemGerEsp := .F.
		(cTab)->(dbGoTop())                               	
		While (cTab)->(!Eof())		
			ZAH->(DBGOTO((cTab)->RECZAH))
			if cCodigoZah <> ZAH->ZAH_CODIGO
				cCodigoZah := ZAH->ZAH_CODIGO
				lTemGerEsp := .F.
				nCargo     := Val((cTab)->CARGO)
			endif
			IF ZAH->(!EOF()) .AND. !EMPTY((cTab)->CARGO)
				RECLOCK("ZAH",.F.)
				if (cTab)->CARGO == "3" .and. (cTab)->CENTROCUST $ cParGer
					lTemGerEsp := .T.
					if ZAH->ZAH_NIVEL == "01"
						ZAH->ZAH_VLRMIN := 0.00
					else
						ZAH->ZAH_VLRMIN := VAL(aVlrAlc[07][1])
					endif
					ZAH->ZAH_VLRMAX := VAL(aVlrAlc[07][2])   					 					
				elseif (cTab)->CARGO == "5" // casagrande
					if ZAH->ZAH_NIVEL == "01"
						ZAH->ZAH_VLRMIN := 0.00
					else
						ZAH->ZAH_VLRMIN := VAL(aVlrAlc[06][1])
					endif
					ZAH->ZAH_VLRMAX := VAL(aVlrAlc[06][2])   					 					
				elseif (cTab)->CARGO == "4"				
					if ZAH->ZAH_NIVEL == "01"
						ZAH->ZAH_VLRMIN := 0.00
					else
						if lTemGerEsp
							ZAH->ZAH_VLRMIN := 20000.01
						else
							ZAH->ZAH_VLRMIN := VAL(aVlrAlc[05][1])
						endif
					endif
					ZAH->ZAH_VLRMAX := VAL(aVlrAlc[05][2])   					 					
				else
					if ZAH->ZAH_NIVEL == "01"
						ZAH->ZAH_VLRMIN := 0.00
					else
						ZAH->ZAH_VLRMIN := VAL(aVlrAlc[VAL((cTab)->CARGO)+1][1])
					endif
					ZAH->ZAH_VLRMAX := VAL(aVlrAlc[VAL((cTab)->CARGO)+1][2])   					 					
				endif
				if Val((cTab)->CARGO) <> 0 .and. Val((cTab)->CARGO) <> 5
					if Val((cTab)->CARGO) <> nCargo  // Ocorreu uma "quebra" na hierarquia pelo cargo, ou seja, 
					                                 // o cargo atual não é o imediatamente superior ao cargo anterior.
						nCargo          := Val((cTab)->CARGO)
						ZAH->ZAH_VLRMIN := VAL(aVlrAlc[nCargo][1])  // atualizo o valor mínimo com o do cargo anterior.
					endif
				endif
				MSUNLOCK()
			ENDIF
			(cTab)->(dbSkip())
			if nCargo == 0
				nCargo += 2
			elseif nCargo <> 4
				nCargo += 1
			endif	
		Enddo
		(cTab)->(dbCloseArea())
		
		// Ajuste dos valores para os grupos que tem somente 3 níveis.
/*
		DbSelectArea("ZAH")
		ZAH->(DbSetOrder(1))
		cTabNivel := GetNextAlias()
		BeginSQL Alias cTabNivel
			SELECT R1.CODIGOZAH AS CODIGO
			FROM (SELECT ZAH.ZAH_CODIGO AS CODIGOZAH,
			             COUNT(*) AS QTD
			      FROM %TABLE:ZAH% ZAH
			      WHERE ZAH_FILIAL = %XFILIAL:ZAH%
			        AND ZAH_TIPO = 'H'
			        AND ZAH.D_E_L_E_T_ = '' 
			      GROUP BY ZAH_CODIGO) AS R1
			WHERE R1.QTD = 3
			ORDER BY R1.CODIGOZAH
		ENDSQL
		(cTabNivel)->(dbGoTop())                               	
		while (cTabNivel)->(!Eof())
			if ZAH->(DbSeek(xFilial("ZAH")+(cTabNivel)->CODIGO+"02"))
				if ZAH->ZAH_VLRMIN == 10000.01 .or. ZAH->ZAH_VLRMIN == 15000.01
					RECLOCK("ZAH",.F.)
					ZAH->ZAH_VLRMIN := 3000.01
					MSUNLOCK()
				endif
			endif
			(cTabNivel)->(DbSkip())
		enddo
		(cTabNivel)->(dbCloseArea())	 
*/
		
	END TRANSACTION
	
	DBSELECTAREA("ZAH")
	ZAH->(DBGOTOP())

/*	cTab:= GetNextAlias()

	BeginSQL Alias cTab
	SELECT DISTINCT ZAA.ZAA_MAT, ZAA.ZAA_MATSUP, ZAA.ZAA_LGREDE, ZAA.ZAA_NOME, ZAA.ZAA_CC
	FROM %TABLE:ZAA% ZAA
	WHERE ZAA_FILIAL=%XFILIAL:ZAA%
	AND NOT EXISTS(SELECT DISTINCT ZAH.ZAH_MAT FROM %TABLE:ZAH% ZAH WHERE ZAH_FILIAL=%XFILIAL:ZAH% AND ZAH.ZAH_MAT = ZAA.ZAA_MAT AND ZAH.D_E_L_E_T_ = ' ')
	AND ZAA.ZAA_CARGO NOT IN('0', '1')
	AND LEN(ZAA.ZAA_CODHIE) > 7
	AND ZAA.D_E_L_E_T_ = ' '
	ORDER BY ZAA.ZAA_MAT	
	ENDSQL

	(cTab)->(dbGoTop())  

	If !((cTab)->(Eof()))

		While !((cTab)->(Eof()))

			//Verifica se o código do grupo de aprovação já existe
			IF (nPosCod:=ASCAN(aGrupos,{|x| TRIM(x[1])== TRIM((cTSup)->CCUSTO) .and. TRIM(x[2])== TRIM((cTSup)->MATRIC) })) == 0
				cCodGrp:= GETSX8NUM("ZAH","ZAH_CODIGO")
				ZAH->(ConfirmSX8())	
			ELSE
				cCodGrp:= aGrupos[nPosCod][3]
			ENDIF	
		
			cCCusto:= (cTab)->ZAA_CC
			
			DbSelectArea("CTD")
			
			CTD->(DbSetOrder(1))
			
			CTD->(MsSeek(xFilial("CTD") + (cTab)->ZAA_CC))
			
			cDesGrp:= AllTrim(CTD->CTD_DESC01)
			
			DbSelectArea("ZAH")
			
			RECLOCK("ZAH",.T.)
			ZAH->ZAH_FILIAL := XFILIAL("ZAH")
			ZAH->ZAH_CODIGO := cCodGrp
			ZAH->ZAH_CC	    := cCCusto
			ZAH->ZAH_DESCRI := cDesGrp
			ZAH->ZAH_TIPO	:= "H"   // Gestores
			ZAH->ZAH_MAT	:= (cTab)->ZAA_MAT
			ZAH->ZAH_LGREDE := (cTab)->ZAA_LGREDE
			ZAH->ZAH_NOME   := (cTab)->ZAA_NOME
			ZAH->ZAH_MATSUP := (cTab)->ZAA_MATSUP
			ZAH->ZAH_NIVEL  := cNivel   				 					
			ZAH->(MSUNLOCK())
			
			ZAH->(DbCloseArea())
			
			CTD->(DbCloseArea())
			
			(cTab)->(DbSkip())
			
		EndDo
		
	EndIf
	
	(cTab)->(dbCloseArea())	 
*/
	
	TRB->(DbCloseArea()) 
	
	if Len(aMatricula)
		// envia e-mail das matrícúlas que não foram criados os grupos
		CCAW04EM(aMatricula)
	endif	
	
	msginfo("Processo finalizado!")
	
RETURN
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCA04INT
Realiza a manutenção dos grupos de aprovação no Fluig 
@author  	Carlos Henrique
@since     	28/07/2017
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
static Function CCA04INT(cTipoGrp,lJob)
	Local cTab			:= GetNextAlias()
//	Local cTabPar		:= ""
	Local oObjWs		:= WSCIEE04():new()
	Local cusername	:= TRIM(GetMv("MV_ECMPUBL",.F.,""))
	Local cpassword	:= TRIM(GetMv("MV_ECMPSW",.F.,""))
	Local ncompanyId	:= VAL(GetMv("MV_ECMEMP",.F.,""))
	Local aGrpDel		:= {}
	Local oRet			:= nil
	Local cGrupoId	:= ""
	Local nTotGrp		:= 0
	Local nItem		:= 0
	Local nCnt		:= 0
	DEFAULT lJob	:= .F.

	oObjWs:cusername	:= cusername
	oObjWs:cpassword	:= cpassword 
	oObjWs:ncompanyId	:= ncompanyId

	//Realiza a consulta de todos os grupos de aprovação incluidos no Fluig
	IF oObjWs:getGroups()
		oRet := oObjWs:oWsGetGroupsResult
		For nCnt := 1 to Len(oRet:oWsItem)
			cGrupoId := oRet:oWsItem[nCnt]:cGroupId
			IF !EMPTY(cGrupoId) .AND. LEFT(cGrupoId,1) == cTipoGrp
				oObjWs:cGroupId := cGrupoId
				If !(oObjWs:deleteGroup())
					aAdd(aGrpDel, oObjWs:cGroupId)
				EndIf
			EndIf
		Next nCnt
	ENDIF

	//Seleciona todos os códigos de grupos de aprovação de acordo com tipo 
	BeginSQL Alias cTab
	SELECT ZAH_TIPO,ZAH_CODIGO,ZAH_DESCRI FROM %TABLE:ZAH% ZAH
	WHERE ZAH_FILIAL=%XFILIAL:ZAA%
	AND ZAH_TIPO=%EXP:cTipoGrp%
	AND ZAH.D_E_L_E_T_='' 
	GROUP BY ZAH_TIPO,ZAH_CODIGO,ZAH_DESCRI
	ORDER BY ZAH_CODIGO				
	ENDSQL

	//GETLastQuery()[2]		 
	(cTab)->(dbSelectArea((cTab)))    

	COUNT TO nTotGrp

	IF !lJob
		ProcRegua(nTotGrp)
	ENDIF	

	(cTab)->(dbGoTop())                               	
	While (cTab)->(!Eof())

		IncProc("Integrando Grupo de aprovação(tipo:"+(cTab)->ZAH_TIPO+"): "+ (cTab)->ZAH_CODIGO + "-" + (cTab)->ZAH_DESCRI + ".")	

		//Verifica se o grupo foi excluido	    
		IF ASCAN(aGrpDel,{|x| x == TRIM((cTab)->ZAH_TIPO + (cTab)->ZAH_CODIGO) }) == 0	    	 			

			oObjWs:oWScreateGroupgroups:oWSitem:= {}
			AADD(oObjWs:oWScreateGroupgroups:oWSitem,WSClassNew( "ECMGroupServiceService_groupDto2"))
			nItem:= LEN(oObjWs:oWScreateGroupgroups:oWSitem)	
			oObjWs:oWScreateGroupgroups:oWSitem[nItem]:ncompanyId			:= ncompanyId
			oObjWs:oWScreateGroupgroups:oWSitem[nItem]:cfoo      			:= {}
			oObjWs:oWScreateGroupgroups:oWSitem[nItem]:cgroupId         	:= (cTab)->ZAH_TIPO + (cTab)->ZAH_CODIGO
			oObjWs:oWScreateGroupgroups:oWSitem[nItem]:cgroupDescription	:= (cTab)->ZAH_DESCRI				

			// Inclui um grupo no Fluig
			IF oObjWs:createGroup()
				CCA04PAR(cusername,cpassword,ncompanyId,(cTab)->ZAH_TIPO,(cTab)->ZAH_CODIGO)	
			ENDIF	
		ELSE			
			oObjWs:oWSupdateGroupgroups:oWSitem:= {}
			AADD(oObjWs:oWSupdateGroupgroups:oWSitem,WSClassNew( "ECMGroupServiceService_groupDto2"))
			nItem:= LEN(oObjWs:oWSupdateGroupgroups:oWSitem)	
			oObjWs:oWSupdateGroupgroups:oWSitem[nItem]:ncompanyId			:= ncompanyId
			oObjWs:oWSupdateGroupgroups:oWSitem[nItem]:cfoo      			:= {}
			oObjWs:oWSupdateGroupgroups:oWSitem[nItem]:cgroupId         	:= (cTab)->ZAH_TIPO + (cTab)->ZAH_CODIGO
			oObjWs:oWSupdateGroupgroups:oWSitem[nItem]:cgroupDescription	:= (cTab)->ZAH_DESCRI		

			// Atualiza um grupo no Fluig
			IF oObjWs:updateGroup()
				CCA04PAR(cusername,cpassword,ncompanyId,(cTab)->ZAH_TIPO,(cTab)->ZAH_CODIGO)	
			ENDIF						    	
		ENDIF

		(cTab)->(dbSkip())	
	End  
	(cTab)->(dbCloseArea()) 

	msginfo("Processo finalizado!")

RETURN
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCA04PAR
Realiza a manutenção dos participantes dos grupos de aprovação no Fluig
@author  	Carlos Henrique
@since     	28/07/2017
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
static Function CCA04PAR(cusername,cpassword,ncompanyId,cTipoGrp,cCodGrp)
	Local cTabPar	:= GetNextAlias()
	Local oObjWsUs	:= WSCIEE05():new()
	Local nItem		:= 0
	Local cMatSub   := ""
	Local aColleagues := {}

	oObjWsUs:cusername	:= cusername
	oObjWsUs:cpassword	:= cpassword
	oObjWsUs:ncompanyId	:= ncompanyId

	//Realiza a exclusão dos participantes do grupo
	oObjWsUs:cGroupId := AllTrim(cTipoGrp+cCodGrp)
	
	IF oObjWsUs:getColleagueGroupsByGroupId()      
	
		aColleagues := oObjWsUs:oWSgetColleagueGroupsByGroupIdresult:oWsItem
	     
		For nItem := 1 To Len(aColleagues)	
			
			oObjWsUs:cGroupId     := aColleagues[nItem]:cGroupId
			oObjWsUs:cColleagueId := aColleagues[nItem]:cColleagueId
			If !(oObjWsUs:deleteColleagueGroup())
				U_uCONOUT(GetWSCError())
			EndIf	
		Next
	ENDIF

	//Seleciona todos os participantes do grupo
	BeginSQL Alias cTabPar
		SELECT * FROM %TABLE:ZAH% ZAH
		WHERE ZAH_FILIAL=%XFILIAL:ZAH%
		AND ZAH_TIPO=%EXP:cTipoGrp%
		AND ZAH_CODIGO=%EXP:cCodGrp%
		AND ZAH.D_E_L_E_T_='' 
		ORDER BY ZAH_NIVEL				
	ENDSQL

	//GETLastQuery()[2]		 
	(cTabPar)->(dbSelectArea((cTabPar)))                    
	(cTabPar)->(dbGoTop())   
	IF (cTabPar)->(!Eof())

		oObjWsUs:cusername	:= cusername
		oObjWsUs:cpassword	:= cpassword
		oObjWsUs:ncompanyId	:= ncompanyId

		oObjWsUs:OWSCREATECOLLEAGUEGROUPCOLLEAGUEGROUPS:OWSITEM:= {}

		DbSelectArea("ZAA")

		ZAA->(DbSetOrder(1))

		While (cTabPar)->(!Eof())

			cMatSub := ""

			ZAA->(MsSeek(xFilial("ZAA") + ALLTRIM((cTabPar)->ZAH_MAT)))

			If !Empty(ZAA->ZAA_MATSUB)

				If ZAA->ZAA_DTISUB <= dDataBase .And. ZAA->ZAA_DTFSUB > dDataBase
				
					cMatSub := AllTrim(ZAA->ZAA_MATSUB)
					
				EndIf

			EndIf

			AADD(oObjWsUs:OWSCREATECOLLEAGUEGROUPCOLLEAGUEGROUPS:OWSITEM,WSClassNew( "ECMColleagueGroupServiceService_colleagueGroupDto"))
			nItem:= LEN(oObjWsUs:OWSCREATECOLLEAGUEGROUPCOLLEAGUEGROUPS:OWSITEM)
			oObjWsUs:OWSCREATECOLLEAGUEGROUPCOLLEAGUEGROUPS:OWSITEM[nItem]:ncompanyId   := ncompanyId
			oObjWsUs:OWSCREATECOLLEAGUEGROUPCOLLEAGUEGROUPS:OWSITEM[nItem]:cfoo         := {}
			oObjWsUs:OWSCREATECOLLEAGUEGROUPCOLLEAGUEGROUPS:OWSITEM[nItem]:cgroupId     := (cTabPar)->ZAH_TIPO + (cTabPar)->ZAH_CODIGO
			
			If !Empty(cMatSub)
			
				oObjWsUs:OWSCREATECOLLEAGUEGROUPCOLLEAGUEGROUPS:OWSITEM[nItem]:ccolleagueId := cMatSub
			
			Else
			
				oObjWsUs:OWSCREATECOLLEAGUEGROUPCOLLEAGUEGROUPS:OWSITEM[nItem]:ccolleagueId := ALLTRIM((cTabPar)->ZAH_MAT)
			
			EndIf
			
			(cTabPar)->(dbSkip())	
		End

		// Adiciona os participantes do grupo
		IF oObjWsUs:createColleagueGroup()
			U_uCONOUT("Participantes do grupo integrado com sucesso!!")
		Endif
	Endif
	(cTabPar)->(dbCloseArea())		

RETURN
/*/{Protheus.doc} CCA04GRP
Função que cria grupos no fluig para Workflow de aprovação por duas pessoas
@author felipe ruiz
@since 18/04/2017
@version 6

@type function
/*/
/*/{Protheus.doc} CCA04GRP
//TODO Descrição auto-gerada.
@author carlos.henrique
@since 10/10/2017
@version undefined

@type function
/*/
/*/{Protheus.doc} CCA04GRP
//TODO Descrição auto-gerada.
@author carlos.henrique
@since 10/10/2017
@version undefined

@type function
/*/
/*/{Protheus.doc} CCA04GRP
//TODO Descrição auto-gerada.
@author carlos.henrique
@since 10/10/2017
@version undefined

@type function
/*/
/*
Static function CCA04GRP()
	Local nI
	Local oObjWs	:= WSCIEE04():new()
	Local oObjIt
	Local oObjWsUs
	Local oObjUsIt
	Local oObjVerUs
	Local oRet      
	Local oGrupo
	Local cQuery    := ""
	Local cAlias    := GetNextAlias()
	Local cAliasSup
	Local cAliasGrp
	Local cMatSup   := "" 
	Local aSuperior := {}
	Local aUsuarios := {}
	Local aDel      := {}

	cQuery += "SELECT ZAA_MAT, ZAA_MATSUP" + CRLF
	cQuery += "FROM " + RetSqlName("ZAA") + " ZAA" + CRLF
	cQuery += "WHERE ZAA.ZAA_FILIAL = '" + xFilial("ZAA") + "'" + CRLF
	cQuery += "AND   ZAA.ZAA_MAT != 'admin'" + CRLF
	cQuery += "AND   ZAA.D_E_L_E_T_ = ' '"

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),cAlias, .F., .T.)

	(cAlias)->(DbGoTop())

	If !((cAlias)->(EOF()))

		oObjWs:cusername		:= TRIM(GetMv("MV_ECMPUBL",.F.,""))
		oObjWs:cpassword		:= TRIM(GetMv("MV_ECMPSW",.F.,"")) 
		oObjWs:ncompanyId		:= VAL(GetMv("MV_ECMEMP",.F.,""))

		oObjWs:getGroups()

		oRet := oObjWs:oWsGetGroupsResult

		aDel := {}

		For nI := 1 to Len(oRet:oWsItem)

			cGrupoId := oRet:oWsItem[nI]:cGroupId

			If SubStr(cGrupoId, 1, 2) == "CX"

				oObjWs:cGroupId := cGrupoId

				If !(oObjWs:deleteGroup())

					aAdd(aDel, oObjWs:cGroupId)

				EndIf

			EndIf

		Next

		oObjWs:oWsCreateGroupGroups := ECMGroupServiceService_groupDtoArray2():new()

		oObjVerUs := WSCIEE02():new()

		oObjVerUs:cusername	:= TRIM(GetMv("MV_ECMPUBL",.F.,""))
		oObjVerUs:cpassword	:= TRIM(GetMv("MV_ECMPSW",.F.,"")) 
		oObjVerUs:ncompanyId	:= VAL(GetMv("MV_ECMEMP",.F.,""))

		If oObjVerUs:getColleagues()

			For nI := 1 To Len(oObjVerUs:oWsGetColleaguesResult:oWsItem)

				aAdd(aUsuarios, oObjVerUs:oWsGetColleaguesResult:oWsItem[nI]:cColleagueId)

			Next

		EndIf

		(cAlias)->(DbGoTop())

		While !((cAlias)->(EOF()))

			If !(aScan(aUsuarios, {|x| x == AllTrim((cAlias)->ZAA_MATSUP)}) == 0)

				cQuery := ""

				cAliasSup := GetNextAlias()

				cQuery += "SELECT ZAA_MAT, ZAA_MATSUP, ZAA_CARGO" + CRLF
				cQuery += "FROM " + RetSqlName("ZAA") + " ZAA" + CRLF
				cQuery += "WHERE ZAA.ZAA_FILIAL = '" + xFilial("ZAA") + "'" + CRLF
				cQuery += "AND   ZAA.ZAA_MAT = '" + AllTrim((cAlias)->ZAA_MATSUP) + "'" + CRLF
				cQuery += "AND   ZAA.D_E_L_E_T_ = ' '"

				dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),cAliasSup, .F., .T.)

				(cAliasSup)->(DbGoTop())

				If !((cAliasSup)->(EOF()))

					oObjIt := ECMGroupServiceService_groupDto2():new()

					oObjIt:ncompanyId        := VAL(GetMv("MV_ECMEMP",.F.,""))
					oObjIt:cfoo              := {}

					If Val((cAliasSup)->ZAA_CARGO) == 4

						oObjIt:cgroupDescription := "CX" + AllTrim((cAlias)->ZAA_MATSUP) 
						oObjIt:cgroupId          := "CX" + AllTrim((cAlias)->ZAA_MATSUP) 						

					Else

						oObjIt:cgroupDescription := "CX" + AllTrim((cAlias)->ZAA_MATSUP) + "-" + AllTrim((cAliasSup)->ZAA_MATSUP)
						oObjIt:cgroupId          := "CX" + AllTrim((cAlias)->ZAA_MATSUP) + "-" + AllTrim((cAliasSup)->ZAA_MATSUP)					

					EndIf

					If aScan(aSuperior, {|x| x[1] == oObjIt:cgroupId}) == 0

						aAdd(oObjWs:oWsCreateGroupGroups:oWSitem, oObjIt)

						If oObjWs:createGroup()

							oObjWsUs:= WSCIEE05():new()

							oObjWsUs:cusername		:= TRIM(GetMv("MV_ECMPUBL",.F.,""))
							oObjWsUs:cpassword		:= TRIM(GetMv("MV_ECMPSW",.F.,"")) 
							oObjWsUs:ncompanyId		:= VAL(GetMv("MV_ECMEMP",.F.,""))													

							If aScan(aDel,{|x| AllTrim(x) == oObjIt:cgroupId}) > 0

								oObjWsUs:cGroupId := oObjIt:cgroupId

								If oObjWsUs:getColleagueGroupsByGroupId()

									oGrupos := oObjWsUs:oWSgetColleagueGroupsByGroupIdresult:oWsItem 

									For nI := 1 To Len(oGrupos)

										oObjWsUs:cGroupId     := oGrupos[nI]:cGroupId
										oObjWsUs:cColleagueId := oGrupos[nI]:cColleagueId

										If !(oObjWsUs:deleteColleagueGroup())
											GetWSCError()
										EndIf

									Next

								EndIf

							EndIf

							oObjWsUs:oWScreateColleagueGroupColleagueGroups := ECMColleagueGroupServiceService_colleagueGroupDtoArray():new()

							oObjUsIt := ECMColleagueGroupServiceService_colleagueGroupDto():new()

							oObjUsIt:ccolleagueId := AllTrim((cAlias)->ZAA_MATSUP)
							oObjUsIt:ncompanyId   := VAL(GetMv("MV_ECMEMP",.F.,""))
							oObjUsIt:cfoo         := {}
							oObjUsIt:cgroupId     := oObjIt:cgroupId

							aAdd(oObjWsUs:oWScreateColleagueGroupColleagueGroups:oWSitem, oObjUsIt)

							If Val((cAliasSup)->ZAA_CARGO) != 4

								oObjWsUs:createColleagueGroup()

								oObjUsIt := ECMColleagueGroupServiceService_colleagueGroupDto():new()

								oObjUsIt:ccolleagueId := AllTrim((cAliasSup)->ZAA_MATSUP)
								oObjUsIt:ncompanyId   := VAL(GetMv("MV_ECMEMP",.F.,""))
								oObjUsIt:cfoo         := {}
								oObjUsIt:cgroupId     := oObjIt:cgroupId

								aAdd(oObjWsUs:oWScreateColleagueGroupColleagueGroups:oWSitem, oObjUsIt)

							EndIf

							oObjWsUs:createColleagueGroup()

							cAliasGrp := GetNextAlias()

							cQuery := ""

							cQuery += "SELECT ZAA_MAT" + CRLF
							cQuery += "FROM " + RetSqlName("ZAA") + " ZAA" + CRLF
							cQuery += "WHERE ZAA.ZAA_FILIAL = '" + xFilial("ZAA") + "'" + CRLF
							cQuery += "AND   ZAA.ZAA_MATSUP = '" + AllTrim((cAlias)->ZAA_MATSUP) + "'" + CRLF
							cQuery += "AND   EXISTS("

							cQuery += "SELECT ZAA2.ZAA_MAT FROM " + RetSqlName("ZAA") + " ZAA2 "
							cQuery += "WHERE ZAA2.ZAA_FILIAL = '" + xFilial("ZAA") + "' "
							cQuery += "AND ZAA2.ZAA_MAT = ZAA.ZAA_MATSUP "
							cQuery += "AND ZAA2.ZAA_MATSUP = '" + AllTrim((cAliasSup)->ZAA_MATSUP) + "' "
							cQuery += "AND ZAA2.D_E_L_E_T_ = ' ') "

							cQuery += "AND   ZAA.D_E_L_E_T_ = ' '"

							dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),cAliasGrp, .F., .T.)

							(cAliasGrp)->(DbGoTop())

							DbSelectArea("ZAA")

							ZAA->(DbSetOrder(1))

							While !((cAliasGrp)->(EOF()))

								If ZAA->(MsSeek(xFilial("ZAA") + AllTrim((cAliasGrp)->ZAA_MAT)))

									RecLock("ZAA", .F.)

									ZAA->ZAA_GRPFLG := oObjIt:cgroupId

									ZAA->(MsUnLock())

								EndIf

								(cAliasGrp)->(DbSkip())

							EndDo

							(cAliasGrp)->(DbCloseArea())

							ZAA->(DbCloseArea())

						EndIf							

					EndIf

				EndIf

				(cAliasSup)->(DBCloseArea())

			EndIf

			(cAlias)->(DbSkip())

		EndDo

	EndIf

	(cAlias)->(DbCloseArea())

Return
*/
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCA04SCH
Agendamento de atualização dos grupos de aprovação no Fluig
@author  	Carlos Henrique
@since     	28/07/2017
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
USER FUNCTION CCA04SCH(aParam)
	LOCAL cEmp		:= ""
	LOCAL cFil		:= ""
//	local cQuery	:= ""
	local cAlias	
	Default aParam := {"01", "0001"}
	
	If aParam == Nil
		U_uCONOUT("Parametro invalido => CCA04SCH")
	ELSE	
		cEmp := alltrim(aParam[1])
		cFil := alltrim(aParam[2])

		RpcSetType(3)
		IF RPCSetEnv(cEmp,cFil)                                                                                                              
			U_uCONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CCA04SCH] Processo Iniciado para "+cEmp+"-"+cFil)
			
			cAlias := getNextAlias()
			
			BeginSQL Alias cAlias
				SELECT COUNT(*) AS REGISTROS FROM %TABLE:ZAA% ZAA
				WHERE ZAA_FILIAL = %XFILIAL:ZAA%
				AND ZAA.D_E_L_E_T_ = '' 
			ENDSQL
			
			If (cAlias)->REGISTROS > 10
			
				(cAlias)->(DbCloseArea())
			
				CCA04GER(.T.,"PRENOT")
				CCA04GEFFQ(.T.,"FFQ   ")
				CCA04GEFFQ(.T.,"FOLPAG")
				CCA04GEFFQ(.T.,"SERDIR")
				CCA04GEFFQ(.T.,"REQMAT")
				CCA04GEFFQ(.T.,"BOLAUX")
			
			Else
			
				(cAlias)->(DbCloseArea())
			
			EndIf
//			CCA04INT("H", .T.)		
			U_uCONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CCA04SCH] Processo Finalizado para "+cEmp+"-"+cFil)	
			RpcClearEnv()
		ENDIF	
	EndIf

return

USER FUNCTION CCFGW04(aParam)        
 LOCAL cEmp := ""
 LOCAL cFil := ""

 If aParam == Nil
  U_uCONOUT("Parametro invalido => CCFGW04")
 ELSE 
  cEmp := alltrim(aParam[1])
  cFil := alltrim(aParam[2])

  RpcSetType(3)
  IF RPCSetEnv(cEmp,cFil)                                                                                                              
   U_uCONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CCFGW04] Processo Iniciado para "+cEmp+"-"+cFil)
   U_CCA04PRO(2, .T.)    
   U_uCONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CCFGW04] Processo Finalizado para "+cEmp+"-"+cFil) 
   RpcClearEnv()
  ENDIF 
 EndIf

RETURN

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCA04GEFFQ
Realizando geração dos grupos de aprovação de acordo com a Hierarquia do RH para FFQ
@author  	Danilo José Grodzicki
@since     	29/08/2018
@version  	P.12.17
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
STATIC FUNCTION CCA04GEFFQ(lJob,cCodReg)

//Local cArqTRB
Local cMatSup
Local cNivelAtu
Local cAliasTmp

Local aStruTRB  := {}
//Local cInd1TRB  := ""
//Local cInd2TRB  := ""
Local cTab		:= GetNextAlias()
Local cCodGrp	:= ""
Local cCCusto	:= ""
Local cDesGrp	:= ""
Local cNivel	:= ""
local lTemGrp	:= .F.
Local aGrupos	:= {}
Local nPosCod	:= 0
Local nCntGrp	:= 0
Local nTotGrp	:= 0
Local aVlrAlc	:= {STRTOKARR(AllTrim(GetNewPar("CI_VLRNIV0","0|0")),"|"),;  // Valores para nivel Colaborador             Cargo = 0
STRTOKARR(AllTrim(GetNewPar("CI_VLRNIV1","0|0")),"|"),;                      // Valores para nivel Secretária              Cargo = 1
STRTOKARR(AllTrim(GetNewPar("CI_VLRNIV2","0|999999999.99")),"|"),;           // Valores para nivel Supervisor              Cargo = 2
STRTOKARR(AllTrim(GetNewPar("CI_VLRNIV3","3000.01|999999999.99")),"|"),;     // Valores para nivel Gerência                Cargo = 3
STRTOKARR(AllTrim(GetNewPar("CI_VLRNIV4","10000.01|999999999.99")),"|"),;    // Valores para nivel Superintendência        Cargo = 4
STRTOKARR(AllTrim(GetNewPar("CI_VLRNIV5","30000.01|999999999.99")),"|"),;    // Valores para nivel Superintendência Geral  Cargo = 5
STRTOKARR(AllTrim(GetNewPar("CI_VLRNIV6","3000.01|999999999.99")),"|")}      // Valores para nivel Gerência Específica     Cargo = 3 e centro de custo estar no parâmetro CI_GERESPE 
Local cDesReg	:= POSICIONE("SX5",1,XFILIAL("SX5")+"ZX"+cCodReg,"X5_DESCRI")
Local lTemSuper := .F.
Local cCodigoZah := ""
Local lTemGerEsp := .F.
Local cMatAprFFQ
Local cTabGrp
Local cTabZai
Local cTabPad
Local cMatSupPad
Local cGrpSupPad
Local cGrpAprFFQ
//Local cTabNivel
Local cZAA 		:= ZAA->(DbSeek(xFilial("ZAA")+GetMv("CI_MATSUPE",.F.,"")))
Local cParGer	:= GetMv("CI_GERESPE",.F.,"")
DEFAULT lJob	:= .F.

Private aMatricula := {}

aStruTRB := {{ "NIVEL"     , "C" , FwTamSX3("ZAH_NIVEL")[1]  , 0 },;
             { "MATRIC"    , "C" , FwTamSX3("ZAA_MAT")[1]    , 0 },;
             { "NOME"      , "C" , FwTamSX3("ZAA_NOME")[1]   , 0 },;
             { "LGREDE"    , "C" , FwTamSX3("ZAA_LGREDE")[1] , 0 },;
             { "CCUSTO"    , "C" , FwTamSX3("ZAA_CC")[1]     , 0 },;
             { "CTD_DESC01", "C" , FwTamSX3("CTD_DESC01")[1] , 0 },;
             { "MATSUP"    , "C" , FwTamSX3("ZAA_MATSUP")[1] , 0 },;
             { "CCSUP"     , "C" , FwTamSX3("ZAA_CC")[1]     , 0 },;
             { "CARGO"     , "C" , FwTamSX3("ZAA_CARGO")[1]  , 0 },;
             { "CODHIE"    , "C" , FwTamSX3("ZAA_CODHIE")[1] , 0 } }

U_uCriaTrab("TRB",aStruTRB,{ {"NIVEL","MATRIC"}})

TRB->(DbSetOrder(1))

DbSelectArea("ZAA")
ZAA->(DbSetOrder(01))

DbSelectArea("CTD")
CTD->(DbSetOrder(01))

BEGIN TRANSACTION
	
	// Apaga todos as regras de aprovação do tipo FFQ para gerar novamente
	IF TCSQLEXEC("DELETE "+RETSQLNAME("ZAI")+" WHERE ZAI_FILIAL='"+XFILIAL("ZAI")+"' AND ZAI_REGRA='"+cCodReg+"' AND ZAI_PADRAO = 'T' AND D_E_L_E_T_=''") < 0
		MSGALERT(TCSQLERROR())
		DisarmTransaction()
		BREAK
	ENDIF
	
	BeginSQL Alias cTab
		SELECT * FROM %TABLE:ZAA% ZAA
		WHERE ZAA_FILIAL = %XFILIAL:ZAA%
		AND ZAA.D_E_L_E_T_ = '' 
	ENDSQL
	
	//GETLastQuery()[2]		 
	
	(cTab)->(dbSelectArea((cTab)))
	
	(cTab)->(dbGoTop())                               	
	While (cTab)->(!Eof())	
		// Gera regra de aprovação FFQ
		RECLOCK("ZAI",.T.)
		ZAI->ZAI_FILIAL	:= XFILIAL("ZAI")
		ZAI->ZAI_REGRA	:= cCodReg
		ZAI->ZAI_DESC	:= cDesReg
		ZAI->ZAI_MAT	:= (cTab)->ZAA_MAT
		ZAI->ZAI_MATSUP	:= (cTab)->ZAA_MATSUP	
		ZAI->ZAI_PADRAO := .T.		
		ZAI->ZAI_TIPO   := "F"	
		MSUNLOCK() 
		(cTab)->(dbSkip())	
	End  
	(cTab)->(dbCloseArea())
	
	// Se o código grupo de aprovação do centro de custo já foi gerado antes, mantem o mesmo... 
	BeginSQL Alias cTab
		SELECT ZAH_CC,ZAH_MAT,ZAH_CODIGO FROM %TABLE:ZAH% ZAH
		WHERE ZAH_FILIAL = %XFILIAL:ZAH%
		AND ZAH_NIVEL = '01'
		AND ZAH_TIPO = 'F'
		AND ZAH.D_E_L_E_T_ = '' 
		GROUP BY ZAH_CC,ZAH_MAT,ZAH_CODIGO
		ORDER BY ZAH_CODIGO
	ENDSQL
	
	//GETLastQuery()[2]		 
	
	(cTab)->(dbSelectArea((cTab)))
	
	(cTab)->(dbGoTop())                               	
	While (cTab)->(!Eof())	
		IF ASCAN(aGrupos,{|x| TRIM(x[1]) == TRIM((cTab)->ZAH_CC) .AND. TRIM(x[2]) == TRIM((cTab)->ZAH_MAT) }) == 0
			AADD(aGrupos,{(cTab)->ZAH_CC,(cTab)->ZAH_MAT,(cTab)->ZAH_CODIGO})
		ENDIF	
		(cTab)->(dbSkip())	
	End  
	(cTab)->(dbCloseArea()) 	
	
	// Apaga todos os grupos de aprovação do tipo gestores para gerar novamente
	IF TCSQLEXEC("DELETE "+RETSQLNAME("ZAH")+" WHERE ZAH_FILIAL='"+XFILIAL("ZAH")+"' AND ZAH_TIPO='F' AND D_E_L_E_T_=''") < 0
		MSGALERT(TCSQLERROR())
		DisarmTransaction()
		BREAK
	ENDIF
	
	DBSELECTAREA("ZAH")
	ZAH->(DBSETORDER(2))
	
	// Seleciona todos os superiores cadastro de matriculas do RH
	BeginSQL Alias cTab
		SELECT ZAA.ZAA_MATSUP FROM %TABLE:ZAA% ZAA
		INNER JOIN %TABLE:ZAA% ZAAB ON ZAAB.ZAA_FILIAL = %XFILIAL:ZAA% 
		AND ZAAB.ZAA_MAT = ZAA.ZAA_MATSUP
		AND ZAAB.D_E_L_E_T_= ''
		WHERE ZAA.ZAA_FILIAL = %XFILIAL:ZAA% 
		AND ZAA.ZAA_MATSUP != ''
		AND ZAA.D_E_L_E_T_ = '' 
		GROUP BY ZAA.ZAA_MATSUP
		UNION ALL
		SELECT DISTINCT ZAA.ZAA_MAT
		FROM %TABLE:ZAA% ZAA
		WHERE NOT EXISTS(SELECT DISTINCT ZAH.ZAH_MAT FROM %TABLE:ZAH% ZAH WHERE ZAH.ZAH_FILIAL = %XFILIAL:ZAH% AND ZAH.ZAH_MAT = ZAA.ZAA_MAT AND ZAH.D_E_L_E_T_ = ' ')
		AND ZAA.ZAA_CARGO NOT IN('0','1','5')
		AND ZAA.D_E_L_E_T_ = ' '
	ENDSQL
	
	//GETLastQuery()[2]		 
	
	(cTab)->(dbSelectArea((cTab)))
	
	COUNT TO nTotGrp
	
	IF !lJob
		ProcRegua(nTotGrp)
	ENDIF
	
	(cTab)->(dbGoTop())                               	
	While (cTab)->(!Eof())
		
		nCntGrp++
		IncProc("Processando grupo de aprovação "+ cvaltochar(nCntGrp) + " de " + cvaltochar(nTotGrp) + "." )
				
	//	DbSelectArea("TRB")
	//	ZAP
	U_uCriaTrab("TRB",aStruTRB,{ {"NIVEL","MATRIC"}})
		TRB->(DbSetOrder(1))
		if ZAA->(DbSeek(xFilial("ZAA")+(cTab)->ZAA_MATSUP))
			
			// Não irá gerar grupo de aprovação caso a matrícula seja igual a matrícula superior
			if AllTrim(ZAA->ZAA_MAT) == AllTrim(ZAA->ZAA_MATSUP)
				
				// Armazena em matriz para envio de e-mail
				aadd(aMatricula,{ZAA->ZAA_MAT,ZAA->ZAA_NOME})
				
				(cTab)->(dbSkip())
				loop
					
			endif
			
			nNivel     := 1
			cMatricula := ZAA->ZAA_MAT
			while ZAA->(!Eof()) .and. (AllTrim(ZAA->ZAA_MATSUP) <> "00" .or. AllTrim((cTab)->ZAA_MATSUP) == "79747" .and. nNivel == 1)
				if ZAA->(DbSeek(xFilial("ZAA")+cMatricula))
					if TRB->(!Eof())
						If RecLock("TRB",.F.)
							TRB->CCSUP := ZAA->ZAA_CC
							TRB->(MsUnlock())
						endif
					endif
					If RecLock("TRB",.T.)
						TRB->NIVEL  := StrZero(nNivel,2)
						TRB->MATRIC := ZAA->ZAA_MAT
						TRB->NOME   := ZAA->ZAA_NOME
						TRB->LGREDE := ZAA->ZAA_LGREDE
						TRB->CCUSTO := ZAA->ZAA_CC
						if CTD->(DbSeek(xFilial("CTD")+ZAA->ZAA_CC))
							TRB->CTD_DESC01 := CTD->CTD_DESC01
						else
							TRB->CTD_DESC01 := "GRUPO DE APROVAÇÃO " + AllTrim(ZAA->ZAA_CC)
						endif
						TRB->MATSUP := ZAA->ZAA_MATSUP
						TRB->CARGO  := ZAA->ZAA_CARGO
						TRB->CODHIE := ZAA->ZAA_CODHIE
						TRB->(MsUnlock())
					endif
					nNivel     += 1
					cMatricula := ZAA->ZAA_MATSUP
				endif
			enddo
			
			if TRB->(Eof())
				(cTab)->(dbSkip())
				loop	
			endif
			
			// Verifica se existe o nível Superintendência
			if AllTrim((cTab)->ZAA_MATSUP) <> "79747"
				lTemSuper := .F.
				TRB->(DbGoTop())
				while TRB->(!Eof())
					if TRB->CARGO == "4" .and. TRB->MATSUP <> "00    "
						lTemSuper := .T.
						exit
					endif
					TRB->(DbSkip())
				enddo
			endif
			
			// Não tem o nível Superintendência, inclui o padrão
			if !lTemSuper
				if cZAA
					If RecLock("TRB",.T.)
						TRB->NIVEL  := "99"
						TRB->MATRIC := ZAA->ZAA_MAT
						TRB->NOME   := ZAA->ZAA_NOME
						TRB->LGREDE := ZAA->ZAA_LGREDE
						TRB->CCUSTO := ZAA->ZAA_CC
						if CTD->(DbSeek(xFilial("CTD")+ZAA->ZAA_CC))
							TRB->CTD_DESC01 := CTD->CTD_DESC01
						else
							TRB->CTD_DESC01 := "GRUPO DE APROVAÇÃO " + AllTrim(ZAA->ZAA_CC)
						endif
						TRB->MATSUP := ZAA->ZAA_MATSUP
						TRB->CARGO  := ZAA->ZAA_CARGO
						TRB->CODHIE := ZAA->ZAA_CODHIE
						TRB->(MsUnlock())
					endif
				endif
				TRB->(DbSkip(-1))
				If RecLock("TRB",.F.)
					TRB->NIVEL := StrZero(Val(TRB->NIVEL) + 1,2)
					TRB->(MsUnlock())
				endif
				cNivelAtu := StrZero(Val(TRB->NIVEL) - 1,2)
				TRB->(DbGoBottom())
				If RecLock("TRB",.F.)
					TRB->NIVEL := cNivelAtu
					TRB->(MsUnlock())
				endif
				
				// Ajustar a matrícula superior do nível 02
				cMatSup := TRB->MATRIC  // pego a matrícula do nível 03
				TRB->(DbSkip(-1))
				If RecLock("TRB",.F.)
					TRB->MATSUP := cMatSup
					TRB->(MsUnlock())
				endif
			endif
			
		else
			(cTab)->(dbSkip())
			loop	
		endif
		
		TRB->(DbGoTop())
		if TRB->(!Eof())
			
			cCodGrp := ""
			cCCusto := ""
			
			While TRB->(!Eof())
				
				cNivel := TRB->NIVEL
				
				if TRB->NIVEL <> "01"
					TRB->(DbSkip())
					loop
				endif
				
				if TRB->NIVEL == "01"
					lTemGrp := .F.		
					if ZAH->(DbSeek(XFilial("ZAH")+TRB->MATRIC+cNivel))
						while XFilial("ZAH")+TRB->MATRIC+cNivel == ZAH->ZAH_FILIAL+ZAH->ZAH_MAT+ZAH->ZAH_NIVEL .and. ZAH->(!Eof())
							if ZAH->ZAH_TIPO == "F"
								exit
							endif
							ZAH->(DbSkip())
						enddo
						if XFilial("ZAH")+TRB->MATRIC+cNivel+"F" == ZAH->ZAH_FILIAL+ZAH->ZAH_MAT+ZAH->ZAH_NIVEL+ZAH->ZAH_TIPO .and. ZAH->(!Eof())
							cCodGrp := ZAH->ZAH_CODIGO
							cCCusto := ZAH->ZAH_CC
							lTemGrp := .T.
						endif
					endif
					if !lTemGrp
						//Verifica se o código do grupo de aprovação já existe
						if (nPosCod := ASCAN(aGrupos,{|x| TRIM(x[1])== TRIM(TRB->CCUSTO) .and. TRIM(x[2]) == TRIM(TRB->MATRIC) })) == 0
							cCodGrp := CCA04NUM("F") //GETSX8NUM("ZAH","ZAH_CODIGO")
							//ZAH->(ConfirmSX8())	
						else
							cCodGrp := aGrupos[nPosCod][3]
						endif
						cCCusto := TRB->CCUSTO
						cDesGrp := TRB->CTD_DESC01
					endif
					
					IF TCSQLEXEC("UPDATE "+RETSQLNAME("ZAI")+" SET ZAI_GRUPO='"+cCodGrp+"' WHERE ZAI_REGRA='"+cCodReg+"' AND ZAI_MATSUP='"+(cTab)->ZAA_MATSUP+"' AND ZAI_PADRAO = 'T' AND D_E_L_E_T_=''") < 0
						U_uCONOUT(TCSQLERROR())
						MSGALERT(TCSQLERROR())
						DisarmTransaction()
						BREAK
					ENDIF
					
					//Caso o código do grupo não esteja preenchido não grava 
					IF lTemGrp
						TRB->(DbSkip())
						loop	// Se ja possui grupo pula para a próxima matricula
					ENDIF
				ENDIF
				
				cAliasTmp := GetNextAlias()
				
				BeginSQL Alias cAliasTmp
					%NOPARSER%
					SELECT ZAH.ZAH_CODIGO
					FROM %TABLE:ZAH% ZAH
					WHERE ZAH.D_E_L_E_T_ <> '*'
					  AND ZAH.ZAH_FILIAL = %XFILIAL:ZAH%
					  AND ZAH.ZAH_CODIGO = %EXP:cCodGrp%
					  AND ZAH.ZAH_MAT = %EXP:TRB->MATRIC%
				ENDSQL
				
				U_uCONOUT("novo grupo FFQ - ")
				U_uCONOUT(getlastquery()[2])
				
				(cAliasTmp)->(DbGoTop())
				if (cAliasTmp)->(Eof())
					RECLOCK("ZAH",.T.)
					ZAH->ZAH_FILIAL := XFILIAL("ZAH")
					ZAH->ZAH_CODIGO := cCodGrp
					ZAH->ZAH_CC	    := cCCusto
					ZAH->ZAH_DESCRI := cDesGrp
					ZAH->ZAH_TIPO	:= "F"   // Gestores
					ZAH->ZAH_MAT	:= TRB->MATRIC
					ZAH->ZAH_LGREDE := TRB->LGREDE
					ZAH->ZAH_NOME   := TRB->NOME
					ZAH->ZAH_MATSUP := TRB->MATSUP
					ZAH->ZAH_NIVEL  := cNivel
					MSUNLOCK()
				endif
				(cAliasTmp)->( dbCloseArea() )
				
				TRB->(DbSkip())
			enddo
			
			IF lTemGrp  // se tem grupo, verifico se a matrícula do ZAH tem no TRB.
				DBSELECTAREA("ZAH")
				ZAH->(DBSETORDER(1))
				DbSelectArea("TRB")
				TRB->(DbSetOrder(2))
				if ZAH->(DbSeek(xFilial("ZAH")+cCodGrp))
					while ZAH->ZAH_CODIGO == cCodGrp .and. ZAH->(!Eof())
						if !TRB->(DbSeek(ZAH->ZAH_MAT))
							If RecLock("ZAH",.F.)
								ZAH->(DbDelete())
								ZAH->(MsUnlock())
							endif
						endif
						ZAH->(DbSkip())
					enddo
				endif
				DbSelectArea("TRB")
				TRB->(DbSetOrder(1))
				DBSELECTAREA("ZAH")
				ZAH->(DBSETORDER(2))
			ENDIF
			
		endif
		
		(cTab)->(dbSkip())	
	Enddo  
	(cTab)->(dbCloseArea())
	
	//Atualiza os valores minimo e maximo de aprovação
	DBSELECTAREA("ZAH")
	ZAH->(DBGOTOP())	
	
	cTab := GetNextAlias()
	BeginSQL Alias cTab
		SELECT ZAH.R_E_C_N_O_ AS RECZAH,
		       ZAA.ZAA_CARGO AS CARGO,
		       ZAA.ZAA_CC AS CENTROCUST,
		       ZAA.ZAA_CODHIE AS CODHIE,
		       ZAH_CODIGO AS CODIGOZAH,
		       ZAH_NIVEL AS NIVEL
		FROM %TABLE:ZAH% ZAH
		INNER JOIN %TABLE:ZAA% ZAA ON ZAA_FILIAL = %XFILIAL:ZAA% 
		AND ZAA_MAT = ZAH_MAT
		AND ZAA.D_E_L_E_T_ = ' ' 		
		WHERE ZAH_FILIAL = %XFILIAL:ZAH%
		AND ZAH_TIPO = 'F'
		AND ZAH.D_E_L_E_T_ = '' 
		ORDER BY ZAH_CODIGO, ZAH_NIVEL
	ENDSQL
	
	cCodigoZah := ""
	lTemGerEsp := .F.
	(cTab)->(dbGoTop())                               	
	While (cTab)->(!Eof())		
		ZAH->(DBGOTO((cTab)->RECZAH))
		if cCodigoZah <> ZAH->ZAH_CODIGO
			cCodigoZah := ZAH->ZAH_CODIGO
			lTemGerEsp := .F.
		endif
		IF ZAH->(!EOF()) .AND. !EMPTY((cTab)->CARGO)
			RECLOCK("ZAH",.F.)
			if (cTab)->CARGO == "3" .and. (cTab)->CENTROCUST $ cParGer
				lTemGerEsp := .T.
				if ZAH->ZAH_NIVEL == "01"
					ZAH->ZAH_VLRMIN := 0.00
				else
					ZAH->ZAH_VLRMIN := VAL(aVlrAlc[07][1])
				endif
				ZAH->ZAH_VLRMAX := VAL(aVlrAlc[07][2])   					 					
			elseif (cTab)->CARGO == "5"			
				if ZAH->ZAH_NIVEL == "01"
					ZAH->ZAH_VLRMIN := 0.00
				else
					ZAH->ZAH_VLRMIN := VAL(aVlrAlc[06][1])
				endif
				ZAH->ZAH_VLRMAX := VAL(aVlrAlc[06][2])   					 					
			elseif (cTab)->CARGO == "4"
				if ZAH->ZAH_NIVEL == "01"
					ZAH->ZAH_VLRMIN := 0.00
				else
					if lTemGerEsp
						ZAH->ZAH_VLRMIN := 20000.01
					else
						ZAH->ZAH_VLRMIN := VAL(aVlrAlc[05][1])
					endif
				endif
				ZAH->ZAH_VLRMAX := VAL(aVlrAlc[05][2])   					 					
			else
				if ZAH->ZAH_NIVEL == "01"
					ZAH->ZAH_VLRMIN := 0.00
				else
					ZAH->ZAH_VLRMIN := VAL(aVlrAlc[VAL((cTab)->CARGO)+1][1])
				endif
				ZAH->ZAH_VLRMAX := VAL(aVlrAlc[VAL((cTab)->CARGO)+1][2])   					 					
			endif
			MSUNLOCK()
		ENDIF
		(cTab)->(dbSkip())	
	Enddo
	(cTab)->(dbCloseArea())
	
	IF TCSQLEXEC("UPDATE " + RETSQLNAME("ZAH") + " SET ZAH_VLRMAX = 999999999.99 WHERE ZAH_TIPO = 'F' AND ZAH_VLRMAX <= 0 AND D_E_L_E_T_=''") < 0
		U_uCONOUT(TCSQLERROR())
		MSGALERT(TCSQLERROR())
		DisarmTransaction()
		BREAK
	ENDIF
		// Busco o grupo do superintendente padrão
		cMatSupPad := Alltrim(GetMv("CI_MATSUPE",.F.,""))  // Matricula do superintendente padrão
		cTabPad    := GetNextAlias()
		BeginSQL Alias cTabPad
			SELECT TOP 1 ZAI.ZAI_GRUPO AS GRUPO
			FROM %TABLE:ZAI% ZAI
			WHERE ZAI.ZAI_FILIAL = %XFILIAL:ZAI%
			  AND ZAI.ZAI_MATSUP = %EXP:cMatSupPad%
			  AND ZAI.ZAI_REGRA = 'FFQ'
			  AND ZAI.D_E_L_E_T_ = ''
		ENDSQL
		(cTabPad)->(dbGoTop())                               	
		if (cTabPad)->(!Eof())
			cGrpSupPad := (cTabPad)->GRUPO
		else
			cGrpSupPad := space(29)
		endif
		(cTabPad)->(dbCloseArea())	 
		
		// Busco o grupo do aprovador FFQ
		cMatAprFFQ := Alltrim(GetMv("CI_MAAPFFQ",.F.,""))  // Matricula do aprovador FFQ
		cTabGrp := GetNextAlias()
		BeginSQL Alias cTabGrp
			SELECT TOP 1 ZAI.ZAI_GRUPO AS GRUPO
			FROM %TABLE:ZAI% ZAI
			WHERE ZAI.ZAI_FILIAL = %XFILIAL:ZAI%
			  AND ZAI.ZAI_MATSUP = %EXP:cMatAprFFQ%
			  AND ZAI.ZAI_REGRA = 'FFQ'
			  AND ZAI.D_E_L_E_T_ = ''
		ENDSQL
		(cTabGrp)->(dbGoTop())                               	
		if (cTabGrp)->(!Eof())
			cGrpAprFFQ := (cTabGrp)->GRUPO
		else
			cGrpAprFFQ := space(29)
		endif
		(cTabGrp)->(dbCloseArea())	 
		
		// Busco todos os superintendentes
		cTabZai := GetNextAlias()
		BeginSQL Alias cTabZai
			SELECT ZAI.R_E_C_N_O_ AS RECNO,
			       ZAA.ZAA_MAT AS MAT
			FROM %TABLE:ZAA% ZAA, %TABLE:ZAI% ZAI
			WHERE ZAA.ZAA_FILIAL = %XFILIAL:ZAA%
			  AND ZAA.ZAA_CARGO = '4'
			  AND ZAA.ZAA_TIPHIE <> '0'
			  AND ZAA.ZAA_MATSUP <> '00'
			  AND ZAA.D_E_L_E_T_ = ''
		      AND ZAI.ZAI_FILIAL = %XFILIAL:ZAI%
			  AND ZAI.ZAI_REGRA = 'FFQ'
			  AND ZAI.ZAI_MAT = ZAA.ZAA_MAT
			  AND ZAI.D_E_L_E_T_ = ''
		ENDSQL
		(cTabZai)->(dbGoTop())                               	
		While (cTabZai)->(!Eof())
			ZAI->(DbGoTo((cTabZai)->RECNO))
//			if AllTrim(ZAI->ZAI_MAT) == AllTrim(cMatSupPad)  // Matricula do superintendente padrão, não altero o grupo de aprovação.
//				(cTabZai)->(DbSkip())
//				loop	
			if AllTrim(ZAI->ZAI_MAT) == AllTrim(cMatAprFFQ)  // Matricula do aprovador FFQ, altero o grupo de aprovação para o grupo do superintendente padrão.
				RECLOCK("ZAI",.F.)
				ZAI->ZAI_MATSUP := cMatSupPad  // Matricula do superintendente padrão.
				ZAI->ZAI_GRUPO  := cGrpSupPad  // Grupo de aprovação do superintendente padrão.   					 					
				MSUNLOCK()
			else
				RECLOCK("ZAI",.F.)
				ZAI->ZAI_MATSUP := cMatAprFFQ  // Matricula do aprovador FFQ.
				ZAI->ZAI_GRUPO  := cGrpAprFFQ  // Grupo de aprovação do aprovador FFQ.   					 					
				MSUNLOCK()
			endif
			(cTabZai)->(DbSkip())	
		enddo		
		(cTabZai)->(dbCloseArea())
	
END TRANSACTION

DBSELECTAREA("ZAH")
ZAH->(DBGOTOP())

TRB->(DbCloseArea()) 
if Len(aMatricula)
	// envia e-mail das matrícúlas que não foram criados os grupos
	CCAW04EM(aMatricula)
endif

MsgInfo("Processo finalizado.")
	
Return Nil

static function CCA04NUM(cTipo)

	local cRet 	:= ""
	local cTab	:= getNextAlias()
	local nNum
	
	BeginSQL Alias cTab
	
	SELECT MAX(ZAH_CODIGO)+1 CODIGO
	FROM %table:ZAH%
	WHERE %notdel%
	
	endSql
	
	(cTab)->(dbGoTop())
	
	if (cTab)->(!eof())
	
		nNum := (cTab)->CODIGO
		
		while !(CCA04ENM(strZero(nNum, 20)))
	
			nNum++
	
		enddo
		
		cRet := strZero(nNum, 20)
	
	endif
	
	(cTab)->(dbCloseArea())

return cRet

static function CCA04ENM(cNum)

	local cTab	:= getNextAlias()
	local lRet	:= .T.

	BeginSQL Alias cTab
	
	SELECT ZAH_CODIGO
	FROM %table:ZAH%
	WHERE ZAH_CODIGO = %exp:cNum%
	AND %notdel%
	
	endSql
	
	(cTab)->(dbGoTop())
	
	if (cTab)->(!eof())
		lRet := .F.
	endif
	
	(cTab)->(dbCloseArea())
	
return lRet

/*/{Protheus.doc} CCAW04EM
Rotina de envio de e-mail
@author Danilo José Grodzicki
@since 18/02/2020
@version undefined

@type static function
/*/
Static Functio CCAW04EM(aMatricula)

Local cEmail  	:= TRIM(SuperGetMv("CI_GRPMAIL" ,.F.,"cristiano@ciee.org.br"))
Local cSMTPAddr := ALLTRIM(GetMV("MV_RELSERV"))		// Endereco do servidor SMTP
Local cSMTPPort := GetMV("MV_PORSMTP")     			// Porta do servidor SMTP
Local cUser     := ALLTRIM(GetMV("MV_RELACNT"))    	// Usuario que ira realizar a autenticacao
Local cPass     := ALLTRIM(GetMV("MV_RELPSW"))    	// Senha do usuario
Local nSMTPTime := 60                     			// Timeout SMTP
Local oServer  	:= Nil
Local oMessage 	:= Nil
Local nErr     	:= 0
Local cHtml		:= ""
Local nCnt		:= 0

cHtml+= "<h3 style='-moz-box-sizing: border-box;box-sizing: border-box;orphans: 3;widows: 3;page-break-after: avoid;font-family: inherit;font-weight: 500;line-height: 1.1;color: inherit;margin-top: 20px;margin-bottom: 10px;font-size: 18px;'><b style='-moz-box-sizing: border-box;box-sizing: border-box;font-weight: 700;'>Manutenção de grupos de aprovação RH - " + DTOC(dDataBase) + "</b></h3>"+CRLF
cHtml+= "<h2 style='-moz-box-sizing: border-box;box-sizing: border-box;orphans: 3;widows: 3;page-break-after: avoid;font-family: inherit;font-weight: 500;line-height: 1.1;color: inherit;margin-top: 20px;margin-bottom: 10px;font-size: 18px;'><b style='-moz-box-sizing: border-box;box-sizing: border-box;font-weight: 700;'>Não foi criado grupo de aprovação da(s) matrícula(s) relacionada(s) abaixo, porque a matrícula superior é igual a matrícula do funcionário.</b></h2>"+CRLF
cHtml+= "<table style='-moz-box-sizing: border-box;box-sizing: border-box;border-collapse: collapse!important;border-spacing: 0;background-color: transparent;width: 100%;max-width: 100%;margin-bottom: 20px;'>"+CRLF
cHtml+= "<tbody style='-moz-box-sizing: border-box;box-sizing: border-box;' >"+CRLF
cHtml+= "   <tr style='-moz-box-sizing: border-box;box-sizing: border-box;page-break-inside: avoid;'>"+CRLF
cHtml+= "	  <th style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;text-align: left;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border-top: 1px solid #ddd;'>Matrícula</th>"+CRLF
cHtml+= "	  <th style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;text-align: left;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border-top: 1px solid #ddd;'>Nome</th>"+CRLF
cHtml+= "   </tr>"+CRLF
cHtml+= "<tbody>"+CRLF

For nCnt :=1 TO LEN(aMatricula)
	cHtml+= "   <tr style='-moz-box-sizing: border-box;box-sizing: border-box;page-break-inside: avoid;'>"+CRLF
	cHtml+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ aMatricula[nCnt][1] +"</td>"+CRLF
	cHtml+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ aMatricula[nCnt][2] +"</td>"+CRLF
	cHtml+= "   </tr>"+CRLF
NEXT nCnt

cHtml+= "</tbody>"+CRLF
cHtml+= "</table>"+CRLF

oServer := tMailManager():New()  	// Instancia um novo TMailManager
oServer:setUseTLS(.T.)             	// Usa TLS na conexao

oServer:init("", cSMTPAddr, cUser, cPass,0, cSMTPPort)// Inicializa

// Define o Timeout SMTP
if oServer:SetSMTPTimeout(nSMTPTime) != 0
//alert("[ERROR]Falha ao definir timeout")
	return
endif

// Conecta ao servidor
nErr := oServer:smtpConnect()
if nErr <> 0
//	alert("[ERROR]Falha ao conectar: " + oServer:getErrorString(nErr))
	oServer:smtpDisconnect()
	return
endif

// Realiza autenticacao no servidor
nErr := oServer:smtpAuth(cUser, cPass)
if nErr <> 0
//	alert("[ERROR]Falha ao autenticar: " + oServer:getErrorString(nErr))
	oServer:smtpDisconnect()
	return
endif

// Cria uma nova mensagem (TMailMessage)
oMessage := tMailMessage():new()
oMessage:clear()
oMessage:cFrom    := cUser
oMessage:cTo      := cEmail
oMessage:cCC      := cUser
oMessage:cSubject := "Manutenção de grupos de aprovação RH - " + DTOC(dDataBase)
oMessage:cBody    := cHtml

 // Envia a mensagem
nErr := oMessage:send(oServer)
if nErr <> 0
//	alert("[ERROR]Falha ao enviar: " + oServer:getErrorString(nErr))
	oServer:smtpDisconnect()
	return
endif

// Disconecta do Servidor
oServer:smtpDisconnect()

Return Nil
