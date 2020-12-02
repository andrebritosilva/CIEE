#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TOPCONN.CH"

 /*/{Protheus.doc} CFINA89D
Programa que define o Modelo para ZC8 - Pagamento bolsa Auxulio ANALITICO
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
USER Function CFINA89D()

aRotina	:= MenuDef()
    
Return

Static Function MenuDef()   

aRotina := {}

ADD OPTION aRotina TITLE "Pesquisar"		ACTION "PesqBrw"            OPERATION 1 ACCESS 0 DISABLE MENU
ADD OPTION aRotina TITLE "Visualizar"		ACTION "VIEWDEF.CFINA89D"   OPERATION 2 ACCESS 0
//ADD OPTION aRotina TITLE "Incluir"		ACTION "VIEWDEF.CFINA89D"   OPERATION 3 ACCESS 0
//ADD OPTION aRotina TITLE "Alterar"		ACTION "VIEWDEF.CFINA89D"   OPERATION 4 ACCESS 143
//ADD OPTION aRotina TITLE "Excluir"		ACTION "VIEWDEF.CFINA89D"   OPERATION 5 ACCESS 144
ADD OPTION aRotina TITLE "Imprimir"			ACTION "VIEWDEF.CFINA89D"   OPERATION 8 ACCESS 0

Return aRotina


Static Function ModelDef()  

Local oStruZC8 := Nil
Local oModAnalitco := Nil

oStruZC8 := FWFormStruct(1,"ZC8")

oModAnalitco:= MPFormModel():New("MOVANALIT",/*{ |oModAnalitco| /*PreVldMdl( oModAnalitco ) }*/,/* }*/,/* }*/,/*Cancel*/)  
oModAnalitco:AddFields("MOVANALIT_CAB", Nil/*cOwner*/, oStruZC8 ,/*{||VldGRUP(oModAnalitco)}*/,,/*Carga*/)
oModAnalitco:GetModel("MOVANALIT_CAB"):SetDescription("B.A.Analitico")
oModAnalitco:SetPrimaryKey({"ZC8_FILIAL","ZC8_IDFOL","ZC8_ID"})
                                                                               
Return(oModAnalitco)

//-------------------------------------------------------------------
Static Function ViewDef()

Local oStruZC8 := FWFormStruct(2,"ZC8")
Local oModAnalitco:= FWLoadModel( 'CFINA89D' )
Local oView

oView := FWFormView():New()
//oView:SetUseCursor(.F.)
oView:SetModel(oModAnalitco)
oView:AddField( "MOVANALIT_CAB",oStruZC8)
oView:CreateHorizontalBox("GERAL",100)
//oView:CreateVerticalBox( 'DIREITO',100, 'DIREITO' )
oView:SetOwnerView( "MOVANALIT_CAB","GERAL")
oView:EnableControlBar(.T.)

Return oView 