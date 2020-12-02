#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TOPCONN.CH"

 /*/{Protheus.doc} CFINA89B
Programa que define o Modelo para SRD
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
USER Function CFINA89B()

aRotina	:= MenuDef()
    
Return

Static Function MenuDef()   

aRotina := {}

ADD OPTION aRotina TITLE "Pesquisar"		ACTION "PesqBrw"            OPERATION 1 ACCESS 0 DISABLE MENU
ADD OPTION aRotina TITLE "Visualizar"		ACTION "VIEWDEF.CFINA89B"   OPERATION 2 ACCESS 0
//ADD OPTION aRotina TITLE "Incluir"		ACTION "VIEWDEF.CFINA89B"   OPERATION 3 ACCESS 0
//ADD OPTION aRotina TITLE "Alterar"		ACTION "VIEWDEF.CFINA89B"   OPERATION 4 ACCESS 143
//ADD OPTION aRotina TITLE "Excluir"		ACTION "VIEWDEF.CFINA89B"   OPERATION 5 ACCESS 144
ADD OPTION aRotina TITLE "Imprimir"			ACTION "VIEWDEF.CFINA89B"   OPERATION 8 ACCESS 0

Return aRotina


Static Function ModelDef()  

Local oStruSRD := Nil
Local oModMovime := Nil

oStruSRD := FWFormStruct(1,"SRD")

oModMovime:= MPFormModel():New("MOVIM",/*{ |oModMovime| /*PreVldMdl( oModMovime ) }*/,/* }*/,/* }*/,/*Cancel*/)  
oModMovime:AddFields("MOVIM_CAB", Nil/*cOwner*/, oStruSRD ,/*{||VldGRUP(oModMovime)}*/,,/*Carga*/)
oModMovime:GetModel("MOVIM_CAB"):SetDescription("Movimentos")
oModMovime:SetPrimaryKey({"RD_FILIAL","RD_XIDCNT","RD_XIDLOC"})
                                                                               
Return(oModMovime)

//-------------------------------------------------------------------
Static Function ViewDef()

Local oStruSRD := FWFormStruct(2,"SRD")
Local oModMovime:= FWLoadModel( 'CFINA89B' )
Local oView

oView := FWFormView():New()
//oView:SetUseCursor(.F.)
oView:SetModel(oModMovime)
oView:AddField( "MOVIM_CAB",oStruSRD)
oView:CreateHorizontalBox("GERAL",100)
//oView:CreateVerticalBox( 'DIREITO',100, 'DIREITO' )
oView:SetOwnerView( "MOVIM_CAB","GERAL")
oView:EnableControlBar(.T.)

Return oView 
