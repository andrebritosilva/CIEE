#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} CFINA97
Monitor SPBA - Apuração de IR
@type  Function
@author Carlos Henrique 
@since 05/03/2020
@version version
/*/
User Function CFINA97()
Local oBrowse := FwMBrowse():New()

//SetFunName("GPEM650")

oBrowse:SetAlias("RC1")
oBrowse:SetDescription("Monitor SPBA - Apuração de IR") 
oBrowse:AddLegend("RC1_INTEGR=='0'", "BR_BRANCO"  	, "Pendente de liberação de pagamento")
oBrowse:AddLegend("RC1_INTEGR=='3'", "BR_LARANJA"  	, "Em aprovação Fluig"  )
oBrowse:AddLegend("RC1_INTEGR=='4'", "BR_VERDE"  	, "Aprovado"  )
oBrowse:AddLegend("RC1_INTEGR=='5'", "BR_VERMELHO"  , "Reprovado"  )
oBrowse:AddLegend("RC1_INTEGR=='6'", "BR_AZUL"  	, "Finalizado"  )
oBrowse:SetFilterDefault("ALLTRIM(RC1_NATURE)=='IRF'") //Listar titulos de IR
oBrowse:Activate()						

RETURN
/*/{Protheus.doc} MenuDef
Rotina de definição do menu
@type  Function
@author Carlos Henrique 
@since 05/03/2020
@version version
/*/
Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar"               ACTION "VIEWDEF.CFINA97"    OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Apurar IR"                ACTION "U_C06A92IR"         OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Liberar para pagamento"   ACTION "U_C06A92LP"         OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE "Rel. Conferencia IR"      ACTION "U_CFIN97CON"         OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE "Imprimir DARF"            ACTION "U_CJBK03GR"         OPERATION 4 ACCESS 0

Return(aRotina)
/*/{Protheus.doc} ModelDef
Rotina de definição do MODEL
@type  Function
@author Carlos Henrique 
@since 05/03/2020
@version version
/*/
Static Function ModelDef()
Local oStruCAB 	:= FWFormStruct(1, "RC1")  
Local oModel   	:= MPFormModel():New( 'C6A92MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

oModel:AddFields("RC1MASTER", /*cOwner*/, oStruCAB)
oModel:SetPrimaryKey({"RC1_FILIAL","RC1_NUMTIT"})
oModel:SetDescription("Monitor SPBA - Apuração de IR")
oModel:getModel("RC1MASTER"):SetDescription("Apuração de IR")

Return oModel
/*/{Protheus.doc} ViewDef
Rotina de definição do VIEW
@type  Function
@author Carlos Henrique 
@since 05/03/2020
@version version
/*/
Static Function ViewDef()
Local oView    	:= FWFormView():New()
Local oStruCAB 	:= FWFormStruct(2,"RC1")  
Local oModel   	:= FWLoadModel("CFINA97")           	

oView:SetModel(oModel)
oView:AddField("VIEW_CAB", oStruCAB, "RC1MASTER")

oView:CreateHorizontalBox("SUPERIOR", 100)

oView:SetOwnerView("VIEW_CAB", "SUPERIOR")

Return oView

/*/{Protheus.doc} C06A92IR
Rotina de apuração de IR
@type  Function
@author Carlos Henrique 
@since 05/03/2020
@version version
/*/
User function C06A92IR()

If MsgYesNo("O período a ser apurado está realmente fechado? Essa processo sendo efetivado não poderá ser refeito!", "ATENÇÃO!" )
	SetFunName("GPEM650")
	
	GPEM650()
	
	SetFunName("CFINA97")
EndIf

Return

/*/{Protheus.doc} CJBK03GR
Rotina de apuração de IR
@type  Function
@author André Brito	
@since 22/07/2020
@version version
/*/
User function CJBK03GR()

SetFunName("GPER050")

//U_CFINR085("Relatorio","\spool\")
GPER050()

SetFunName("CFINA97")

Return

/*/{Protheus.doc} CFIN97VLD
Evita duplicidade na apuração de IR
@type  Function
@author Andre Brito
@since 03/08/2020
@version version
/*/
User function CFIN97VLD(dDataDe,dDataAte)

Local aArea	  := GetArea()
Local lRet    := .F.
Local cQuery  := ""
Local cAliAux := GetNextAlias()

cQuery := " SELECT "
cQuery += "   RD_XIDFOL, "
cQuery += "   RD_MAT, "
cQuery += "   RD_XIDCNT, "
cQuery += "   RD_XIDLOC, "
cQuery += "   RD_PERIODO, "
cQuery += "   RD_VALOR "
cQuery += "  FROM "+ RetSqlName("SRD")+ ""
cQuery += " WHERE RD_DATPGT BETWEEN '" + Dtos(dDataDe) + "' AND '" + Dtos(dDataAte) + "'"
cQuery += "   AND RD_PD = '509'"
cQuery += "   AND RD_XNUMTIT = '' AND D_E_L_E_T_ = ' ' "

cQuery := ChangeQuery(cQuery)

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliAux,.T.,.T.)

(cAliAux)->(dbGotop())

While (cAliAux)->(!EOF()) 
	lRet := .T.
	Exit
EndDo

(cAliAux)->(dbCloseArea())

RestArea( aArea )

Return lRet

/*/{Protheus.doc} CFIN97CON
Geração do relatório de conferência
@author André Brito	
@since 04/08/2020
@version 1.0
@type function
/*/
User Function CFIN97CON()

FWMsgRun(,{|| U_CJBK03RS() },,"Gerando relatório de conferência de IR, aguarde..." )

return