#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TOPCONN.CH"

 /*/{Protheus.doc} CFINA89C
Programa que define o Modelo para ZC7 - Pagamento bolsa Auxulio Sintetico
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
USER Function CFINA89C()

 aRotina:= MenuDef()

Return

Static Function MenuDef()   

aRotina:= {}

ADD OPTION aRotina TITLE "Pesquisar"		ACTION "PesqBrw"            OPERATION 1 ACCESS 0 DISABLE MENU
ADD OPTION aRotina TITLE "Visualizar"		ACTION "VIEWDEF.CFINA89C"   OPERATION 2 ACCESS 0
//ADD OPTION aRotina TITLE "Incluir"		ACTION "VIEWDEF.CFINA89C"   OPERATION 3 ACCESS 0
//ADD OPTION aRotina TITLE "Alterar"		ACTION "VIEWDEF.CFINA89C"   OPERATION 4 ACCESS 143
//ADD OPTION aRotina TITLE "Excluir"		ACTION "VIEWDEF.CFINA89C"   OPERATION 5 ACCESS 144
ADD OPTION aRotina TITLE "Imprimir"			ACTION "VIEWDEF.CFINA89C"   OPERATION 8 ACCESS 0

Return aRotina

//ModelDef
Static Function ModelDef()  

Local oStruZC7 := Nil
Local oModZC7 := Nil

oStruZC7 := FWFormStruct(1,"ZC7")

oModZC7:= MPFormModel():New("MOVIMBA",/*{ |oModZC7| /*PreVldMdl( oModZC7 ) }*/,/* }*/,/* }*/,/*Cancel*/)  
oModZC7:AddFields("MOVIMBA_CAB", Nil/*cOwner*/, oStruZC7 ,/*{||VldGRUP(oModZC7)}*/,,/*Carga*/)
oModZC7:GetModel("MOVIMBA_CAB"):SetDescription("B.A.Sintetico")
oModZC7:SetPrimaryKey({"ZC7_FILIAL","ZC7_IDFOL"})
                                                                               
Return(oModZC7)

//ViewDef
Static Function ViewDef()

Local oStruZC7 := FWFormStruct(2,"ZC7")
Local oViewMod:= FWLoadModel( 'CFINA89C' )
Local oView


oView := FWFormView():New()
//oView:SetUseCursor(.F.)
oView:SetModel(oViewMod)
oView:AddField( "MOVIMBA_CAB",oStruZC7)
oView:CreateHorizontalBox("GERAL",100)
//oView:CreateVerticalBox( 'DIREITO',100, 'DIREITO' )
oView:SetOwnerView( "MOVIMBA_CAB","GERAL")
oView:EnableControlBar(.T.)

Return oView 