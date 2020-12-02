#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "FWMBrowse.ch"

 /*/{Protheus.doc} CFINA89E
Programa que define o Modelo ESEPCIFICO para SRA - FUNCIONARIOS
@type  Function
@Luiz Enrique
@since 19/06/2020
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
USER Function CFINA89E()

aRotina	:= MenuDef()

Return

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina de definio do menu
@author  	Luiz Enrique
@since     	19/06/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function MenuDef()

aRotina:= {}

ADD OPTION aRotina TITLE "Pesquisar"	ACTION "PesqBrw"            OPERATION 1 ACCESS 0 DISABLE MENU
ADD OPTION aRotina TITLE "Visualizar"   ACTION "VIEWDEF.CFINA89E"   OPERATION 2 ACCESS 0
//ADD OPTION aRotina TITLE "Incluir"      ACTION "VIEWDEF.CFINA89E" OPERATION 3 ACCESS 0
//ADD OPTION aRotina TITLE "Alterar"      ACTION "VIEWDEF.CFINA89E" OPERATION 4 ACCESS 0
//ADD OPTION aRotina TITLE "Excluir"      ACTION "VIEWDEF.CFINA89E" OPERATION 5 ACCESS 0
ADD OPTION aRotina TITLE "Imprimir"		ACTION "VIEWDEF.CFINA89E"   OPERATION 8 ACCESS 0

Return(aRotina)

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina de definio do MODEL
@author  	Luiz Enrique
@since     	19/06/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function ModelDef()

Local oStruSRA := Nil
Local oModMovime := Nil

oStruSRA := FWFormStruct(1,"SRA")

oModMovime:= MPFormModel():New("MOVIM",/*{ |oModMovime| /*PreVldMdl( oModMovime ) }*/,/* }*/,/* }*/,/*Cancel*/)  
oModMovime:AddFields("MOVIM_CAB", Nil/*cOwner*/, oStruSRA ,/*{||VldGRUP(oModMovime)}*/,,/*Carga*/)
oModMovime:GetModel("MOVIM_CAB"):SetDescription("Bolsa Auxilio")
oModMovime:SetPrimaryKey({"RA_FILIAL","RA_MAT"})

Return oModMovime

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina de definio do VIEW
@author  	Luiz Enrique
@since     	19/06/2020
@version  	P.12
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function ViewDef()

Local oView    := FWFormView():New()
Local oStruSRA := FWFormStruct( 2, "SRA")
Local oModel   := FWLoadModel("CFINA89E")

oView:SetModel(oModel)
oView:AddField("VIEW_CAB"   , oStruSRA, "SRAMASTER")
oView:CreateHorizontalBox("PAINEL", 100)
oView:SetOwnerView("VIEW_CAB"	, "PAINEL")

Return oView