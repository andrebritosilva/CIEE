#Include 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} CFINA91
Monitor SPBA - Cálculo
@type  Function
@author Carlos Henrique
@since 05/03/2020
@version version
/*/
User Function CFINA91()
Local oBrowse := FwMBrowse():New()
Private oGetD 

oBrowse:SetAlias("ZC7")
oBrowse:SetDescription("Monitor SPBA - Cálculo") 
oBrowse:AddLegend("ZC7_STATUS=='1'", "BR_AMARELO"	, "Aguardando identificação de crédito")
oBrowse:AddLegend("ZC7_STATUS=='L'", "BR_LARANJA"	, "Aguardando liberação para calculo")
oBrowse:AddLegend("ZC7_STATUS=='2'", "BR_VERDE" 	, "Aguardando Cálculo")
oBrowse:AddLegend("ZC7_STATUS=='3'", "BR_VERMELHO"  , "Falha no Cálculo")
oBrowse:AddLegend("ZC7_STATUS=='4'", "BR_AZUL"  	, "Cálculo Finalizado aguardando retorno Kairós")
oBrowse:AddLegend("ZC7_STATUS=='5'", "BR_PRETO"  	, "Finalizado")
oBrowse:Activate()						

RETURN
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina de definição do menu
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
// //---------------------------------------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar" ACTION "U_CFINA91V()" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Calcular Folha" ACTION "U_CJOBK02" OPERATION 2 ACCESS 0 
ADD OPTION aRotina TITLE "Liberar Folha sem crédito" ACTION "U_C06A91LIB(1)" OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Liberar Folha para calculo" ACTION "U_C06A91LIB(2)" OPERATION 3 ACCESS 0
 

Return(aRotina)
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Rotina de definição do MODEL
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function ModelDef()

Local aRelat	:= {}
Local oModel	:= Nil
Local oStruCAB 	:= FWFormStruct(1, "ZC7")
Local oStruSRA	:= FWFormStruct(1, "SRA",{|cCpo| ALLTRIM(cCpo)$"RA_MAT/RA_NOME/RA_CIC/RA_BCDEPSA/RA_CTDEPSA/RA_ADMISSA/RA_DEMISSA/RA_DTFIMCT/RA_XDIGAG/RA_XDIGCON " })
Local oStruDet	:= Nil

oModel	:= MPFormModel():New( 'C6A91MD', /*bPreValidacao*/, /*bPosVld*/, /*bCommit*/ , /*bCancel*/ )

//Adiciona campos ao modelo
oStruSRA  := FCPOMODEL(oStruSRA)

//Monta os dados do formulário
oModel:AddFields("ZC7MASTER", /*cOwner*/, oStruCAB)
oModel:SetPrimaryKey({"ZC7_IDFOL"})
oModel:getModel("ZC7MASTER"):SetDescription("Folha")

//Monta os dados do primeiro grid
oModel:AddGrid('SRADETAIL', 'ZC7MASTER', oStruSRA ,/*bLinePre*/,,,,{|oModel,Y| loadFieldG(oModel,Y) })
oModel:GetModel("SRADETAIL"):SetDescription("Matriculas")

oStruDet	:= FWFormStruct(1, "ZC8")
oModel:AddGrid("DETAIL2", "SRADETAIL", oStruDet)
aRelat	:= { {"ZC8_IDFOL", ZC7->ZC7_IDFOL}, {"ZC8_CPF", "RA_CIC"} }
oModel:SetRelation("DETAIL2", aRelat, ZC8->(IndexKey(1)))

oStruDet:= FWFormStruct(1, "SRD")
oModel:AddGrid("DETAIL3", "SRADETAIL", oStruDet)
aRelat	:= { {"RD_XIDFOL", ZC7->ZC7_IDFOL}, {"RD_MAT", "RA_MAT"} }
oModel:SetRelation("DETAIL3", aRelat, SRD->(IndexKey(1)))


//Seta o nome da rotina na enchoice
oModel:SetDescription("Monitor SPBA - Cálculo")

Return oModel
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Rotina de definição do VIEW
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function ViewDef()

Local aCposDet1	:= {}
Local aCposDet2	:= {}
Local aCposDet3	:= {}
Local oView    	:= FWFormView():New()
Local oStruCAB 	:= FWFormStruct(2,"ZC7")
Local oStruSRA	:= Nil
Local oStruDet2	:= Nil
Local oModel   	:= FWLoadModel("CFINA91")

aCposDet1	:= {"RA_MAT", "RA_NOME", "RA_CIC", "RA_BCDEPSA","RA_XDIGAG", "RA_CTDEPSA","RA_XDIGCON","RA_ADMISSA","RA_DEMISSA","RA_DTFIMCT","STATUS"}

oStruSRA	:= FWFormStruct(2, "SRA", {|cCampo|  AScan(aCposDet1 , AllTrim(cCampo)) > 0})

//Adiciona campos a VIEW
oStruSRA    := FCPOVIEW(oStruSRA)

aCposDet2	:= {"ZC8_CPF","ZC8_TIPO", "ZC8_DESCRI", "ZC8_VLCONT", "ZC8_VLPAG", "ZC8_TPKAI", "ZC8_MOTIVO", "ZC8_TOACRE", "ZC8_TODESC", "ZC8_LOTE", "ZC8_SLOTE", "ZC8_DTINTE", "ZC8_HRINTE", "ZC8_JSON"}
oStruDet2	:= FWFormStruct(2, "ZC8", {|cCampo|  AScan(aCposDet2 , AllTrim(cCampo)) > 0})

aCposDet3	:= {"RD_MAT","RD_PD","RD_XDESCPD", "RD_TIPO1","RD_HORAS", "RD_VALOR", "RD_DATPGT", "RD_XOCODES"}
oStruDet3	:= FWFormStruct(2, "SRD", {|cCampo|  AScan(aCposDet3 , AllTrim(cCampo)) > 0})

oView:SetModel(oModel)
oView:AddField("VIEW_CAB", oStruCAB, "ZC7MASTER")
oView:AddGrid("VIEW_SRA", oStruSRA, "SRADETAIL")

oView:AddGrid("VIEW_ITEN2", oStruDet2, "DETAIL2")
oView:AddGrid("VIEW_ITEN3", oStruDet3, "DETAIL3")


oView:CreateHorizontalBox("SUPERIOR", 30)
oView:CreateHorizontalBox("INFERIOR", 35)
oView:CreateHorizontalBox("INFERIOR2", 35)

oView:CreateVerticalBox( 'DIV1', 50, 'INFERIOR2' )
oView:CreateVerticalBox( 'DIV2', 50, 'INFERIOR2' )

oView:SetOwnerView("VIEW_CAB", "SUPERIOR")
oView:SetOwnerView("VIEW_SRA", "INFERIOR")
oView:SetOwnerView("VIEW_ITEN2", "DIV1")
oView:SetOwnerView("VIEW_ITEN3", "DIV2")

oView:AddUserButton("Dependentes","MAGIC_BMP", {|| C0691DEP()} ,"Dependentes")
oView:AddUserButton("Beneficiários","MAGIC_BMP", {|| C0691BEN()} ,"Beneficiários")

Return oView

/*/{Protheus.doc} CFINA91
Rotina de liberação de folha 
@type  Function
@author Djalma Mathias da Silva/Milton
@since 05/03/2020
@version version
/*/
User Function C06A91LIB(nAcao)
Local oOk      	:= LoadBitmap( GetResources(), "LBOK" )   	//CHECKED    //LBOK  //LBTIK // LoadBitMap(GetResources(), "BR_AZUL") 		//
Local oNo      	:= LoadBitmap( GetResources(), "LBNO" )  	//UNCHECKED  //LBNO // LoadBitMap(GetResources(), "BR_VERMELHO") 	
Local oDlg 	    := NIL
Local cTitulo   := ""
Local lMark  	:= .T.
Local aTitulo   := {}
Local cTab      := ""
Local cStatus   := ""

Private oLbx1 	:= NIL

//Liberação para calculo
If nAcao == 1                    

    cTitulo   := "Liberação de Folha sem crédito"
    cStatus   := "1"

//Liberação de folha sem crédito
ElseIf nAcao == 2  

    cTitulo   := "Liberação de Folha para Calculo"
    cStatus   := "L"

EndIf

If Pergunte("LBPGFL01",.T.)
    
    cTab:= GetNextAlias()

    BeginSql Alias cTab
        SELECT * FROM %TABLE:ZC7% ZC7 
        WHERE ZC7_FILIAL= %xfilial:ZC7%
            AND ZC7_STATUS = %EXP:cStatus%
            AND ZC7_IDFOL BETWEEN %EXP:MV_PAR01% AND %EXP:MV_PAR02% 
            AND ZC7_IDCNTT BETWEEN %EXP:MV_PAR03% AND %EXP:MV_PAR04% 
            AND ZC7_IDLOCC BETWEEN %EXP:MV_PAR05% AND %EXP:MV_PAR06% 
            AND ZC7_DTINTE BETWEEN %EXP:MV_PAR07% AND %EXP:MV_PAR08% 
            AND ZC7.D_E_L_E_T_=' ' "
        ORDER BY ZC7_IDFOL,ZC7_IDCNTT,ZC7_IDLOCC 
    EndSql
    
    While (cTab)->(!Eof())

        aAdd(aTitulo,{	lMark,;
                        (cTab)->ZC7_IDFOL,;
                        (cTab)->ZC7_COMPET,;
                        (cTab)->ZC7_IDCNTT,;
                        (cTab)->ZC7_IDLOCC,;
                        (cTab)->ZC7_IDCFGF,;
                        Transform((cTab)->ZC7_QUANT		,"@E 99,999,999,999"),;
                        Transform((cTab)->ZC7_TOTGER	,"@E 99,999,999,999.99"),;
                        Transform((cTab)->ZC7_SALDO		,"@E 99,999,999,999.99")})

    (cTab)->(dBSkip())					
    EndDo

    (cTab)->(dBCloseArea())

    If !EMPTY(aTitulo)

        DEFINE MSDIALOG oDlg TITLE cTitulo FROM 31,58 TO 300,778 	OF oDlg PIXEL
        //@ 033,002 TO 289,660 LABEL cTitulo  OF oDlg PIXEL
        //@ 042,006 SCROLLBOX oScroll HORIZONTAL VERTICAL SIZE 242,650 OF oDlg BORDER  
        @ 05,05 LISTBOX oLbx1 FIELDS HEADER ;
        " ","Id Folha", "Competencia", "Id Contrato", ;
        "Loc contrato", "Id Cfg Folha", "Qtd Estag.", "Valor Total", "Saldo     " ;		
        SIZE 345, 85 OF oDlg PIXEL
        oLbx1:SetArray( aTitulo )

        oLbx1:bLine := {|| {Iif(aTitulo[oLbx1:nAt,1],oOk,oNo),;
                                aTitulo[oLbx1:nAt,2],;
                                aTitulo[oLbx1:nAt,3],;
                                aTitulo[oLbx1:nAt,4],;
                                aTitulo[oLbx1:nAt,5],;
                                aTitulo[oLbx1:nAt,6],;
                                aTitulo[oLbx1:nAt,7],;
                                aTitulo[oLbx1:nAt,8],;
                                aTitulo[oLbx1:nAt,9]}}
		oLbx1:BlDblClick := {|| aTitulo[oLbx1:nAt, 1] := !aTitulo[oLbx1:nAt, 1], VerTodos( aTitulo, @lMark ), oLbx1:Refresh(), oLbx1:Refresh()}

		@ 94, 264 BUTTON "Marcar" SIZE 25 ,12 ACTION ( C06A91MKT(aTitulo) , oLbx1:Refresh(.T.) ) Of oDlg PIXEL
		@ 94, 292 BUTTON "Liberar" SIZE 25 ,12 ACTION ( C06A91PRC(aTitulo,nAcao) , oDlg:End() ) Of oDlg PIXEL
		@ 94, 320 BUTTON "Cancelar" SIZE 25 ,12 ACTION ( oDlg:End() ) Of oDlg PIXEL	
		
		ACTIVATE MSDIALOG oDlg CENTERED									
    Else 
        MsgAlert("Nenhuma folha localizada com os parâmetros informados!","Atenção!")
    EndIf

EndIf 

Return

/*/{Protheus.doc} VerTodos
Rotina de liberação de folha 
@type  Function
@author danilo.grodzicki
@since 15/06/2020
@version version
/*/
Static Function VerTodos( _aVetor, _lChk )

Local lTTrue := .T.
Local nI     := 0

For nI := 1 To Len( _aVetor )
	lTTrue := IIf( !_aVetor[nI][1], .F., lTTrue )
Next nI

_lChk := IIf( lTTrue, .T., .F. )

oLbx1:Refresh()

Return Nil

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C06A91MKT
Marcar todos
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function C06A91MKT(aTitulo)
Local nCnt:= 0

For nCnt:=1 to Len(aTitulo)
	If aTitulo[nCnt,1]
		aTitulo[nCnt,1] := .F.
	Else
		aTitulo[nCnt,1] := .T.
	EndIf
Next nCnt

Return
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C06A91PRC
Processa liberação
@author     Djalma Mathias da Silva/Milton
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function C06A91PRC(aTitulo,nAcao)
Local nGrv:= 0

DBSELECTAREA("ZC7")
ZC7->(DBSETORDER(1))

For nGrv:=1 to Len(aTitulo)
	If aTitulo[nGrv][1]
			
		IF ZC7->(dBSeek(aTitulo[nGrv][2]))
			
			//Liberação de folha sem crédito
			If nAcao == 1           

				C06A91IDE()

			//Liberação para calculo
			ElseIf nAcao == 2    

				RecLock( 'ZC7', .F. )
				ZC7->ZC7_STATUS := '2' 
				ZC7->(MsUnLock())
				
			EndIf

		EndIf
	EndIf
Next nGrv

//Liberação para calculo
If nAcao == 2   
	msginfo("Processo concluído!")
endif

Return
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C06A91IDE
Rotina de identificação de folha sem crédito
@author  	Carlos Henrique
@since     	30/11/2019
@version  	P.12.1.17      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
Static Function C06A91IDE()
Local dDtPgtoFol:= u_VDtFolha(ZC7->ZC7_IDFOL)
Local aPergs	:= {}
Local lLib      := .F.

WHILE !lLib
	aPergs:= {}
	aAdd(aPergs,{1,"Id Folha",ZC7->ZC7_IDFOL,"","","",".F.",50,.T.})
	aAdd(aPergs,{1,"Data pagamento Folha",dDtPgtoFol,"","","","",50,.T.}) 
	aAdd(aPergs,{11,"Informe o motivo","",".T.",".T.",.T.})

	If ParamBox(aPergs ,"Parametros")
		IF (MV_PAR02 < DATE() .OR. MV_PAR02 != DATAVALIDA(MV_PAR02,.T.))
			lLib:= .F.
			MSGALERT( "Informe uma data válida para pagamento")	
		ELSE
			lLib:= .T.
			RecLock('ZC7', .F. )
				ZC7->ZC7_DTPGTO := MV_PAR02
				ZC7->ZC7_MOTLIB := MV_PAR03
				ZC7->ZC7_STATUS := 'L' //Aguardando liberação para calculo
			ZC7->(MsUnLock())	
		ENDIF
	else
		lLib:= .T.	
	endif
END

Return

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} VDtFolha
Consulta data de pagamento na tabela de agendamento
@author  	Carlos henrique
@since     	30/04/2020
@version  	P.12.1.25
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User function VDtFolha(cIdFolh)
Local cTab := GetNextAlias()
Local dRet := CTOD("")

BeginSql alias cTab
	SELECT ZCA_DTAPAG FROM %table:ZCA% ZCA
	WHERE ZCA_FILIAL = %xFilial:ZCA%
	AND ZCA_IDFOL = %exp:cIdFolh%
	AND ZCA.D_E_L_E_T_= ''
	ORDER BY ZCA_REVISA DESC
EndSql
(cTab)->(DbGoTop())
if (cTab)->(!Eof())
	dRet := StoD((cTab)->ZCA_DTAPAG)
endif

(cTab)->(DbCloseArea())

Return dRet

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CFINA91V
Visualiza pagto bolsa auxilio
@author  	Marcelo Moraes
@since     	30/04/2020
@version  	P.12.1.25
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------

User function CFINA91V()

FWExecView('Cobrança','CFINA91',1,,{||.T.})

RETURN

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} loadFieldG
Carrega o Grid SRADETAIL
@author  	Marcelo Moraes
@since     	30/04/2020
@version  	P.12.1.25
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------

Static Function loadFieldG(oFieldModel, lCopy)

local aRet       := {}
local lLoad      := .F.
local _calias    := GetNextAlias()
local _caliasSRD := ""
local _caliasZC8 := ""
local _cIDESTUDA := ""
//local cOcorrencia:= ""
//local dDataPgto	 

local cVeSRD01   := SuperGetMv("CI_SRD01",.F.,"J99") //Cod verba liquido receber na tabela SRD
local cVeSRD02   := SuperGetMv("CI_SRD02",.F.,"004") //Cod verba bolsa auxilio na tabela SRD
local cVeSRD03   := SuperGetMv("CI_SRD03",.F.,"277") //Cod verba auxilio transp na tabela SRD
local cVeSRD04   := SuperGetMv("CI_SRD04",.F.,"509") //Cod verba imposto renda na tabela SRD
local cVeSRD05   := SuperGetMv("CI_SRD05",.F.,"554") //Cod verba pensão alimenticia na tabela SRD

local cVeZC801   := SuperGetMv("CI_ZC801",.F.,"***") //Cod verba liquido receber na tabela ZC8
local cVeZC802   := SuperGetMv("CI_ZC802",.F.,"BAX") //Cod verba bolsa auxilio na tabela ZC8
local cVeZC803   := SuperGetMv("CI_ZC803",.F.,"ATR") //Cod verba auxilio transp na tabela ZC8
local cVeZC804   := SuperGetMv("CI_ZC804",.F.,"***") //Cod verba imposto renda na tabela ZC8
local cVeZC805   := SuperGetMv("CI_ZC805",.F.,"***") //Cod verba pensão alimenticia na tabela ZC8

BeginSql Alias _calias

	SELECT 
	RA_FILIAL,RA_MAT,RA_NOME,RA_CIC,RA_BCDEPSA,RA_CTDEPSA,RA_ADMISSA,RA_DEMISSA,RA_DTFIMCT,ZC7_IDFOL,RA_XATIVO,RA_XDEATIV,RA_XSTATOC,RA_XDIGAG,RA_XDIGCON
	FROM %TABLE:ZC7% ZC7
	INNER JOIN %TABLE:SRA% SRA ON RA_FILIAL=%xfilial:SRA% AND 
									//RA_XIDCONT=ZC7_IDCNTT AND 
									//RA_XIDLOCT=ZC7_IDLOCC AND
									RA_XID IN( 
										SELECT ZC8_NUMTCE FROM %TABLE:ZC8% ZC8
										WHERE ZC7_IDFOL=ZC7_IDFOL
										AND ZC8.%notDel% 
									) AND
									SRA.%notDel%
	WHERE 
	ZC7.%notDel% 
	AND ZC7_FILIAL=%xfilial:ZC7% 
	AND ZC7_IDFOL = %Exp:ZC7->ZC7_IDFOL%

EndSql

WHILE (_calias)->(!EOF())

	lLoad     := .F.	
    _cIDESTUDA := ""

	//Verifica se tem folha calculada para o funcionario

	_caliasSRD := GetNextAlias()

	BeginSql Alias _caliasSRD

		SELECT * FROM %TABLE:SRD% SRD
		WHERE
		SRD.%notDel% 
		AND RD_FILIAL=%xfilial:SRD%
		AND RD_XIDFOL=%Exp:(_calias)->ZC7_IDFOL%
		AND RD_MAT=%Exp:(_calias)->RA_MAT%

	EndSql

	IF (_caliasSRD)->(!EOF())
		lLoad     := .T.	
		_cIDESTUDA := (_calias)->RA_MAT
		//dDataPgto  := SRD->RD_DATPGT
		//cOcorrencia:= SRD->RD_XOCODES
	ENDIF
	
	(_caliasSRD)->(dbCloseArea())


	IF !(lLoad)	
		//Verifica se tem pgto bolsa auxilio para o funcionario

		_caliasZC8 := GetNextAlias()

		BeginSql Alias _caliasZC8

			SELECT * FROM %TABLE:ZC8% ZC8
			WHERE
			ZC8.%notDel% 
			AND ZC8_FILIAL=%xfilial:ZC8%
			AND ZC8_IDFOL=%Exp:(_calias)->ZC7_IDFOL%
			AND ZC8_CPF=%Exp:(_calias)->RA_CIC%

		EndSql

		IF (_caliasZC8)->(!EOF())
			lLoad     := .T.	
			_cIDESTUDA := (_calias)->RA_CIC
			dDataPgto  := Stod(space(8))
			cOcorrencia:= SRA->RA_XDEATIV
		ENDIF
		
		(_caliasZC8)->(dbCloseArea())

	ENDIF

	IF lLoad
		
		aAdd(aRet,{0, {(_calias)->RA_MAT,;
						 (_calias)->RA_NOME,;
						 (_calias)->RA_CIC,;
						 STOD((_calias)->RA_ADMISSA),;
						 STOD((_calias)->RA_DEMISSA),;
						 (_calias)->RA_BCDEPSA,;
						 (_calias)->RA_XDIGAG,;
						 (_calias)->RA_CTDEPSA,; 
						 (_calias)->RA_XDIGCON,;
						STOD((_calias)->RA_DTFIMCT),;
						 VlrColuna((_calias)->ZC7_IDFOL,_cIDESTUDA,cVeSRD01,cVeZC801),; 
						 VlrColuna((_calias)->ZC7_IDFOL,_cIDESTUDA,cVeSRD02,cVeZC802),;
						 VlrColuna((_calias)->ZC7_IDFOL,_cIDESTUDA,cVeSRD03,cVeZC803),;
						 VlrColuna((_calias)->ZC7_IDFOL,_cIDESTUDA,cVeSRD04,cVeZC804),;
						 VlrColuna((_calias)->ZC7_IDFOL,_cIDESTUDA,cVeSRD05,cVeZC805),;
						  Iif((_calias)->RA_XSTATOC$"1|3","BR_VERMELHO","BR_VERDE")}})

	ENDIF

	(_calias)->(DBSKIP())
	
END 

(_calias)->(dbCloseArea())

Return aRet

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} FCPOMODEL
Adiciona campos ao model 
@author  	Marcelo Moraes
@since     	30/04/2020
@version  	P.12.1.25
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function FCPOMODEL(oStruSRA)

//Liquido Receber
oStruSRA:AddField( ;                   // Ord. Tipo Desc.
	AllTrim( 'Liq Receber' ) , ;         // [01] C Titulo do campo  'Agrupamento'
	AllTrim( 'Liq Receber' ) , ;         // [02] C ToolTip do campo
	'LIQRECEB' , ;				   	   // [03] C identificador (ID) do Field
	'N' , ; 						   // [04] C Tipo do campo
	10 , ; 							   // [05] N Tamanho do campo
	02 , ;							   // [06] N Decimal do campo
	, ;     						   // [07] B Code-block de validação do campo
	, ; 	    					   // [08] B Code-block de validação When do campo
	NIL , ;				 			   // [09] A Lista de valores permitido do campo
	NIL , ; 						   // [10] L Indica se o campo tem preenchimento obrigatório
	NIL , ; 						   // [11] B Code-block de inicializacao do campo
	NIL , ; 						   // [12] L Indica se trata de um campo chave
	NIL , ; 						   // [13] L Indica se o campo pode receber valor em uma operação de update.
	.T. )

//Bolsa auxilio
oStruSRA:AddField( ;                   // Ord. Tipo Desc.
	AllTrim( 'Bolsa Aux' ) , ;         // [01] C Titulo do campo  'Agrupamento'
	AllTrim( 'Bolsa Aux' ) , ;         // [02] C ToolTip do campo
	'BOLSAUX' , ;				   	   // [03] C identificador (ID) do Field
	'N' , ; 						   // [04] C Tipo do campo
	10 , ; 							   // [05] N Tamanho do campo
	02 , ;							   // [06] N Decimal do campo
	, ;     						   // [07] B Code-block de validação do campo
	, ; 	    					   // [08] B Code-block de validação When do campo
	NIL , ;				 			   // [09] A Lista de valores permitido do campo
	NIL , ; 						   // [10] L Indica se o campo tem preenchimento obrigatório
	NIL , ; 						   // [11] B Code-block de inicializacao do campo
	NIL , ; 						   // [12] L Indica se trata de um campo chave
	NIL , ; 						   // [13] L Indica se o campo pode receber valor em uma operação de update.
	.T. )

//Auxilio transporte
oStruSRA:AddField( ;                   // Ord. Tipo Desc.
	AllTrim( 'Aux Transp' ) , ;         // [01] C Titulo do campo  'Agrupamento'
	AllTrim( 'Aux Transp' ) , ;         // [02] C ToolTip do campo
	'AUXTRANSP' , ;				   	   // [03] C identificador (ID) do Field
	'N' , ; 						   // [04] C Tipo do campo
	10 , ; 							   // [05] N Tamanho do campo
	02 , ;							   // [06] N Decimal do campo
	, ;     						   // [07] B Code-block de validação do campo
	, ; 	    					   // [08] B Code-block de validação When do campo
	NIL , ;				 			   // [09] A Lista de valores permitido do campo
	NIL , ; 						   // [10] L Indica se o campo tem preenchimento obrigatório
	NIL , ; 						   // [11] B Code-block de inicializacao do campo
	NIL , ; 						   // [12] L Indica se trata de um campo chave
	NIL , ; 						   // [13] L Indica se o campo pode receber valor em uma operação de update.
	.T. )

//Imposto Renda
oStruSRA:AddField( ;                   // Ord. Tipo Desc.
	AllTrim( 'IRRF' ) , ;         // [01] C Titulo do campo  'Agrupamento'
	AllTrim( 'IRRF' ) , ;         // [02] C ToolTip do campo
	'IRRF' , ;				   	   // [03] C identificador (ID) do Field
	'N' , ; 						   // [04] C Tipo do campo
	10 , ; 							   // [05] N Tamanho do campo
	02 , ;							   // [06] N Decimal do campo
	, ;     						   // [07] B Code-block de validação do campo
	, ; 	    					   // [08] B Code-block de validação When do campo
	NIL , ;				 			   // [09] A Lista de valores permitido do campo
	NIL , ; 						   // [10] L Indica se o campo tem preenchimento obrigatório
	NIL , ; 						   // [11] B Code-block de inicializacao do campo
	NIL , ; 						   // [12] L Indica se trata de um campo chave
	NIL , ; 						   // [13] L Indica se o campo pode receber valor em uma operação de update.
	.T. )

//Pensão alimenticia
oStruSRA:AddField( ;                   // Ord. Tipo Desc.
	AllTrim( 'Pensão Alim' ) , ;         // [01] C Titulo do campo  'Agrupamento'
	AllTrim( 'Pensão Alim' ) , ;         // [02] C ToolTip do campo
	'PENSALIM' , ;				   	   // [03] C identificador (ID) do Field
	'N' , ; 						   // [04] C Tipo do campo
	10 , ; 							   // [05] N Tamanho do campo
	02 , ;							   // [06] N Decimal do campo
	, ;     						   // [07] B Code-block de validação do campo
	, ; 	    					   // [08] B Code-block de validação When do campo
	NIL , ;				 			   // [09] A Lista de valores permitido do campo
	NIL , ; 						   // [10] L Indica se o campo tem preenchimento obrigatório
	NIL , ; 						   // [11] B Code-block de inicializacao do campo
	NIL , ; 						   // [12] L Indica se trata de um campo chave
	NIL , ; 						   // [13] L Indica se o campo pode receber valor em uma operação de update.
	.T. )

//Status
oStruSRA:AddField( ;							// Ord. Tipo Desc.
					AllTrim('STATUS') , ; 		// [01] C Titulo do campo
                    AllTrim('Ativo/Inativo') , ;// [02] C ToolTip do campo
                    'STATUS' , ;             	// [03] C identificador (ID) do Field
                    'C' , ;                     // [04] C Tipo do campo
                    50 , ;                      // [05] N Tamanho do campo
                    0 , ;                       // [06] N Decimal do campo
                    NIL , ;                     // [07] B Code-block de validação do campo
                    NIL , ;                     // [08] B Code-block de validação When do campo
                    NIL , ;                     // [09] A Lista de valores permitido do campo
                    NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
                    NIL , ;  					// [11] B Code-block de inicializacao do campo
                    NIL , ;                     // [12] L Indica se trata de um campo chave
                    NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
                    .T. )                       // [14] L Indica se o campo é virtual

Return oStruSRA

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} FCPOVIEW
Adiciona campos a VIEW
@author  	Marcelo Moraes
@since     	18/06/2020
@version  	P.12.1.25
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function FCPOVIEW(oStruSRA)

//Liquido Receber
oStruSRA:AddField( ; 					// Ord. Tipo Desc.
	'LIQRECEB' , ; 						// [01] C Nome do Campo
	'66' , ; 								// [02] C Ordem
	'Liq Receber' , ;		 				// [03] C Titulo do campo
	'Liq Receber' , ; 						// [04] C Descrição do campo
	{ 'HELP' } , ;							// [05] A Array com Help
	'N' , ; 								// [06] C Tipo do campo
	'@E 999,999,999.99', ; 					// [07] C Picture
	NIL , ; 								// [08] B Bloco de Picture Var
	'' , ; 									// [09] C Consulta F3
	.F. , ; 								// [10] L Indica se o campo é evitável
	NIL , ; 								// [11] C Pasta do campo
	NIL , ; 								// [12] C Agrupamento do campo
	NIL , ;				 					// [13] A Lista de valores permitido do campo (Combo)
	NIL , ; 								// [14] N Tamanho Máximo da maior opção do combo
	NIL , ; 								// [15] C Inicializador de Browse
	.T. , ; 								// [16] L Indica se o campo é virtual
	NIL ) 									// [17] C Picture Variável

//Bolsa auxilio
oStruSRA:AddField( ; 					// Ord. Tipo Desc.
	'BOLSAUX' , ; 							// [01] C Nome do Campo
	'67' , ; 								// [02] C Ordem
	'Bolsa Aux' , ;		 					// [03] C Titulo do campo
	'Bolsa Aux' , ; 						// [04] C Descrição do campo
	{ 'HELP' } , ;							// [05] A Array com Help
	'N' , ; 								// [06] C Tipo do campo
	'@E 999,999,999.99', ; 					// [07] C Picture
	NIL , ; 								// [08] B Bloco de Picture Var
	'' , ; 									// [09] C Consulta F3
	.F. , ; 								// [10] L Indica se o campo é evitável
	NIL , ; 								// [11] C Pasta do campo
	NIL , ; 								// [12] C Agrupamento do campo
	NIL , ;				 					// [13] A Lista de valores permitido do campo (Combo)
	NIL , ; 								// [14] N Tamanho Máximo da maior opção do combo
	NIL , ; 								// [15] C Inicializador de Browse
	.T. , ; 								// [16] L Indica se o campo é virtual
	NIL ) 									// [17] C Picture Variável

//Auxilio transporte
oStruSRA:AddField( ; 					// Ord. Tipo Desc.
	'AUXTRANSP' , ; 						// [01] C Nome do Campo
	'68' , ; 								// [02] C Ordem
	'Aux Transp' , ;		 				// [03] C Titulo do campo
	'Aux Transp' , ; 						// [04] C Descrição do campo
	{ 'HELP' } , ;							// [05] A Array com Help
	'N' , ; 								// [06] C Tipo do campo
	'@E 999,999,999.99', ; 					// [07] C Picture
	NIL , ; 								// [08] B Bloco de Picture Var
	'' , ; 									// [09] C Consulta F3
	.F. , ; 								// [10] L Indica se o campo é evitável
	NIL , ; 								// [11] C Pasta do campo
	NIL , ; 								// [12] C Agrupamento do campo
	NIL , ;				 					// [13] A Lista de valores permitido do campo (Combo)
	NIL , ; 								// [14] N Tamanho Máximo da maior opção do combo
	NIL , ; 								// [15] C Inicializador de Browse
	.T. , ; 								// [16] L Indica se o campo é virtual
	NIL ) 									// [17] C Picture Variável

//Imposto Renda
oStruSRA:AddField( ; 					// Ord. Tipo Desc.
	'IRRF' , ; 						// [01] C Nome do Campo
	'69' , ; 								// [02] C Ordem
	'IRRF' , ;		 				// [03] C Titulo do campo
	'IRRF' , ; 						// [04] C Descrição do campo
	{ 'HELP' } , ;							// [05] A Array com Help
	'N' , ; 								// [06] C Tipo do campo
	'@E 999,999,999.99', ; 					// [07] C Picture
	NIL , ; 								// [08] B Bloco de Picture Var
	'' , ; 									// [09] C Consulta F3
	.F. , ; 								// [10] L Indica se o campo é evitável
	NIL , ; 								// [11] C Pasta do campo
	NIL , ; 								// [12] C Agrupamento do campo
	NIL , ;				 					// [13] A Lista de valores permitido do campo (Combo)
	NIL , ; 								// [14] N Tamanho Máximo da maior opção do combo
	NIL , ; 								// [15] C Inicializador de Browse
	.T. , ; 								// [16] L Indica se o campo é virtual
	NIL ) 									// [17] C Picture Variável

//Pensão Alimenticia
oStruSRA:AddField( ; 					// Ord. Tipo Desc.
	'PENSALIM' , ; 						// [01] C Nome do Campo
	'70' , ; 								// [02] C Ordem
	'Pensão Alim' , ;		 				// [03] C Titulo do campo
	'Pensão Alim' , ; 						// [04] C Descrição do campo
	{ 'HELP' } , ;							// [05] A Array com Help
	'N' , ; 								// [06] C Tipo do campo
	'@E 999,999,999.99', ; 					// [07] C Picture
	NIL , ; 								// [08] B Bloco de Picture Var
	'' , ; 									// [09] C Consulta F3
	.F. , ; 								// [10] L Indica se o campo é evitável
	NIL , ; 								// [11] C Pasta do campo
	NIL , ; 								// [12] C Agrupamento do campo
	NIL , ;				 					// [13] A Lista de valores permitido do campo (Combo)
	NIL , ; 								// [14] N Tamanho Máximo da maior opção do combo
	NIL , ; 								// [15] C Inicializador de Browse
	.T. , ; 								// [16] L Indica se o campo é virtual
	NIL ) 									// [17] C Picture Variável

//Status
	oStruSRA:AddField( ; 		// Ord. Tipo Desc.
	'STATUS' , ; 			// [01] C Nome do Campo
	'00' , ; 				// [02] C Ordem
	'Status' , ;		 	// [03] C Titulo do campo
	'Status' , ; 			// [04] C Descrição do campo
	{ 'HELP' } , ;			// [05] A Array com Help
	'C' , ; 				// [06] C Tipo do campo
	'@BMP', ; 				// [07] C Picture
	NIL , ; 				// [08] B Bloco de Picture Var
	'' , ; 					// [09] C Consulta F3
	.F. , ; 				// [10] L Indica se o campo é evitável
	NIL , ; 				// [11] C Pasta do campo
	NIL , ; 				// [12] C Agrupamento do campo
	NIL , ;				 	// [13] A Lista de valores permitido do campo (Combo)
	NIL , ; 				// [14] N Tamanho Máximo da maior opção do combo
	NIL , ; 				// [15] C Inicializador de Browse
	.T. , ; 				// [16] L Indica se o campo é virtual
	NIL ) 					// [17] C Picture Variável

Return oStruSRA

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} VlrColuna
Retorna valor das colunas 
@author  	Marcelo Moraes
@since     	30/04/2020
@version  	P.12.1.25
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function VlrColuna(cIDFOL,_cIDESTUDA,cVerbSRD,cVerbZC8)

local nRet       := 0
local cAliasVLRC := GetNextAlias()

IF ZC7->ZC7_STATUS $ "4/5"

	BeginSql Alias cAliasVLRC

		SELECT SUM(RD_VALOR) AS VALOR FROM %TABLE:SRD% SRD
		WHERE
		SRD.%notDel% 
		AND RD_FILIAL=%xfilial:SRD%
		AND RD_XIDFOL=%Exp:cIDFOL%
		AND RD_MAT=%Exp:_cIDESTUDA%
		AND RD_PD=%Exp:cVerbSRD%

	EndSql

	IF (cAliasVLRC)->(!EOF())
		nRet := (cAliasVLRC)->VALOR	
	ENDIF
	
	(cAliasVLRC)->(dbCloseArea())

ELSE

	BeginSql Alias cAliasVLRC

		SELECT SUM(ZC8_VLPAG) AS VALOR FROM %TABLE:ZC8% ZC8
		WHERE
		ZC8.%notDel% 
		AND ZC8_FILIAL=%xfilial:ZC8%
		AND ZC8_IDFOL=%Exp:cIDFOL%
		AND ZC8_CPF=%Exp:_cIDESTUDA%
		AND ZC8_TPKAI=%Exp:cVerbZC8%

	EndSql

	IF (cAliasVLRC)->(!EOF())
		nRet := (cAliasVLRC)->VALOR	
	ENDIF
	
	(cAliasVLRC)->(dbCloseArea())


ENDIF

Return(nRet)


Static Function C0691DEP()
Private cCadastro := ""

DBSELECTAREA("SRA")
SRA->(dbSetOrder(1))
IF SRA->(dbSeek(xFilial("SRA") + FWFldGet("RA_MAT") ))
	FWExecView("Dependentes", "GPEA020", MODEL_OPERATION_VIEW,, {|| .T.}, {|| .T.}, 40,, {|| .T.})
ELSE
	MsgAlert("Não há dependentes vinculados", "Atenção")
ENDIF

Return

Static Function C0691BEN()

DBSELECTAREA("SRA")
SRA->(dbSetOrder(1))
IF SRA->(dbSeek(xFilial("SRA") + FWFldGet("RA_MAT") ))
	GPEA280(2)
ELSE
	MsgAlert("Não há beneficiários vinculados", "Atenção")
ENDIF

Return
