#Include 'Protheus.ch'
#Include 'Fwmvcdef.ch'

/*/{Protheus.doc} CCADK08
Monitor integração Kairós - DW3
@author danilo.grodzicki
@since 18/05/2020
@version 12.1.25
@type user function
/*/
User Function CCADK08()

Local oBrowse := Nil

oBrowse := FwMBrowse():New()
oBrowse:SetAlias('ZCL')
oBrowse:SetDescription('Monitor integração Kairós - DW3')
oBrowse:AddLegend( "ZCL_STATUS == '1'", "GREEN", "Integrado com Sucesso" )
oBrowse:AddLegend( "ZCL_STATUS == '2'", "RED"  , "Erro Integração"       )
oBrowse:Activate()

Return

/*/{Protheus.doc} MenuDef
Monitor integração Kairós - DW3
@author danilo.grodzicki
@since 18/05/2020
@version 12.1.25
@type static function
/*/
Static Function MenuDef()

Local aRotina := {}

ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.CCADK08' OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE 'Legenda'    ACTION 'U_CCK08LEG()'    OPERATION 6 ACCESS 0
ADD OPTION aRotina TITLE 'Imprimir'   ACTION 'VIEWDEF.CCADK08' OPERATION 8 ACCESS 0

Return(aRotina)

/*/{Protheus.doc} ModelDef
Monitor integração Kairós - DW3
@author danilo.grodzicki
@since 18/05/2020
@version 12.1.25
@type static function
/*/
Static Function ModelDef()

Local oModel   := Nil
Local oStruZCL := FWFormStruct(1,'ZCL',/*bAvalCampo*/,/*lViewUsado*/)

oModel := MPFormModel():New('ZCL001MO',/*bPreValidacao*/,{ |oModel| ValModelo( oModel ) }/*bPosValidacao*/,/*bCommit*/,/*bCancel*/ )

oModel:AddFields('ZCLMASTER',/*cOwner*/,oStruZCL,/*bPreValidacao*/,/*bPosValidacao*/,/*bCarga*/)
oModel:SetDescription('Monitor integração Kairós - DW3')

oModel:SetPrimaryKey({})

Return(oModel)

/*/{Protheus.doc} ViewDef
Monitor integração Kairós - DW3
@author danilo.grodzicki
@since 18/05/2020
@version 12.1.25
@type static function
/*/
Static Function ViewDef()

Local oView    := Nil
Local oModel   := FWLoadModel('CCADK08')
Local oStruZCL := FWFormStruct(2,'ZCL')

oView := FWFormView():New()

oView:SetModel(oModel)
oView:AddField('VIEW_ZCL', oStruZCL,'ZCLMASTER')

oView:CreateHorizontalBox('TELA',100)
oView:SetOwnerView('VIEW_ZCL','TELA')

Return(oView)

/*/{Protheus.doc} CCK08LEG
Legenda do monitor integração Kairós - DW3
@author danilo.grodzicki
@since 18/05/2020
@version 12.1.25
@type user function
/*/
User Function CCK08LEG()

BrwLegenda("Status Integração","Legenda", { {"BR_VERDE"     , OemToAnsi("Integrado com Sucesso")},;
											{"BR_VERMELHO"  , OemToAnsi("Erro Integação")       }})

Return Nil

/*/{Protheus.doc} ValModelo
Legenda do monitor integração Kairós - DW3
@author danilo.grodzicki
@since 18/05/2020
@version 12.1.25
@type static function
/*/
Static Function ValModelo(oModel)

//Local nOperation := oModel:GetOperation()
//Local oModelAtv  := FWModelActive()

Return(.T.)

/*/{Protheus.doc} ZCL001MO
Monitor integração Kairós - DW3
@author danilo.grodzicki
@since 18/05/2020
@version 12.1.25
@type user function
/*/
User Function ZCL001MO()

Local oObj
Local cIdPonto
Local cIdModel

Local aParam     := PARAMIXB
//Local oModelAtv  := FWModelActive()

If aParam <> Nil
	
	oObj      := aParam[1]
	cIdPonto  := aParam[2]
	cIdModel  := aParam[3]
		
endif

Return(.T.)