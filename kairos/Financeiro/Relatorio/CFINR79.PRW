#Include 'Protheus.ch'
#include "Report.ch"

/*/{Protheus.doc} CFINR79
Relatório conferência Serasa
@author danilo.grodzicki
@since 30/06/2020
@version P12.1.25
@type user function
/*/
User Function CFINR79()

Private oReport
Private oSection

Private cTab    := GetNextAlias()
Private aParam	:= {}
Private aParRet := {}

aAdd(aParam,{1,"Contrato"               ,space(FwTamSx3("ZC0_CODIGO")[1]),"@!","","ZC0" ,"",70,.F.})
aAdd(aParam,{1,"Local do Contrato"      ,space(FwTamSx3("ZC1_LOCCTR")[1]),"@!","","ZC13","",70,.F.})
aAdd(aParam,{1,"Carteira"               ,space(FwTamSx3("ZC1_LOCCTR")[1]),"@!","",""    ,"",50,.F.})
aAdd(aParam,{1,"Dt. Vencimento de"      ,CtoD("")                        ,""  ,"",""    ,"",50,.F.})
aAdd(aParam,{1,"Dt. Vencimento até"     ,CtoD("")                        ,""  ,"",""    ,"",50,.F.})
aAdd(aParam,{1,"Dt. Retirada Serasa de" ,CtoD("")                        ,""  ,"",""    ,"",50,.F.})
aAdd(aParam,{1,"Dt. Retirada Serasa até",CtoD("")                        ,""  ,"",""    ,"",50,.F.})

if ParamBox(aParam,"Informe os parâmetros para emissão do relatório conferência Serasa",@aParRet,{|| U_CFF79VAL()})
	if MsgYesNo("Confirma a emissão do relatório conferência Serasa ?")
		FwMsgRun(,{|| U_CFF79SEL() }, "Aguarde...", "Selecionando títulos.")
		(cTab)->(DbGoTop())
		if (cTab)->(Eof())
			MsgStop("Não foram encontrados títulos para os parâmetros informados.","ATENÇÃO")
		else
			oReport := CFF79MOREL()
			oReport:PrintDialog()
			oReport:ParamReadOnly(.T.)
		endif
		(cTab)->(DbCloseArea())
	endif
endif

Return

/*/{Protheus.doc} CFF79VAL
Validação dos parâmetros
@author danilo.grodzicki
@since 30/06/2020
@version P12.1.25
@type user function
/*/
User Function CFF79VAL()

Local lRet := .T.

if Empty(MV_PAR01) .and. Empty(MV_PAR02) .and. Empty(MV_PAR03) .and. Empty(MV_PAR04) .and. Empty(MV_PAR05) .and. Empty(MV_PAR06) .and. Empty(MV_PAR07)
	MsgInfo("É obrigatório o preenchimento de pelo menos um parâmetro.","ATENÇÃO")
	lRet := .F.
endif

Return(lRet)

/*/{Protheus.doc} CFF79SEL
Seleção dos títulos de acordo com os parâmetros passados
@author danilo.grodzicki
@since 30/06/2020
@version P12.1.25
@type user function
/*/
User Function CFF79SEL()

Local cCndQyr := ""

if !Empty(MV_PAR01)
	cCndQyr += " AND SE1.E1_XIDCNT = '" + MV_PAR01 + "'"
endif

if !Empty(MV_PAR02)
	cCndQyr += " AND SE1.E1_XIDLOC = '" + MV_PAR02 + "'"
endif

if !Empty(MV_PAR03)
	cCndQyr += " AND SE1.E1_PORTADO = SEE.EE_CODIGO"
	cCndQyr += " AND SE1.E1_AGEDEP = SEE.EE_AGENCIA"
	cCndQyr += " AND SE1.E1_CONTA = SEE.EE_CONTA"
	cCndQyr += " AND SEE.EE_CODCART = '" + MV_PAR03 + "'"
endif

if !Empty(MV_PAR04)
	cCndQyr += " AND SE1.E1_VENCREA >= '" + DtoS(MV_PAR04) + "'"
endif

if !Empty(MV_PAR05)
	cCndQyr += " AND SE1.E1_VENCREA <= '" + DtoS(MV_PAR05) + "'"
endif

if !Empty(MV_PAR06)
	cCndQyr += " AND SE1.E1_XDARQSE >= '" + DtoS(MV_PAR06) + "'"
endif

if !Empty(MV_PAR07)
	cCndQyr += " AND SE1.E1_XDARQSE <= '" + DtoS(MV_PAR07) + "'"
endif

cCndQyr := "%" + cCndQyr + "%"

if Empty(MV_PAR03)  // Carteira
	BeginSql alias cTab
		%NOPARSER%
		SELECT SE1.R_E_C_N_O_ AS RECNOSE1
		FROM %table:SE1% SE1
		WHERE SE1.E1_FILIAL = %xfilial:SE1%
		%EXP:cCndQyr%
		AND SE1.%notDel%
	EndSql
else
	BeginSql alias cTab
		%NOPARSER%
		SELECT SE1.R_E_C_N_O_ AS RECNOSE1
		FROM %table:SE1% SE1, %table:SEE% SEE
		WHERE SE1.E1_FILIAL = %xfilial:SE1% AND SEE.EE_FILIAL = %xfilial:SEE%
		%EXP:cCndQyr%
		AND SE1.%notDel%
		AND SEE.%notDel%
	EndSql
endif

//GETLastQuery()[2]

Return

/*/{Protheus.doc} CFF79MOREL
Monta o relatório
@author danilo.grodzicki
@since 30/06/2020
@version P12.1.25
@type user function
/*/
Static Function CFF79MOREL()

Local cTitulo := "Relatório conferência Serasa"
Local cDescri := "Listagem dos títulos para conferência Serasa."

oReport := TReport():New("CFINR79", cTitulo,, {|oReport| CFF79MODET(oReport)}, cDescri, .T.,, .F.,, .T.)

oReport:oPage:lLandScape := .T.
oReport:oPage:lPortRait  := .F.
oReport:nFontBody        := 6
oReport:SetEdit(.F.)

oSection := TRSection():New(oReport,OemToAnsi(""),{"SE1", "ZC1"},,,,,.T.)

Return(oReport)

/*/{Protheus.doc} CFF79MODET
Monta a linha detalhe do relatório
@author danilo.grodzicki
@since 30/06/2020
@version P12.1.25
@type user function
/*/
Static Function CFF79MODET(oReport)

Local nDiasAtr
Local dDtIncSera

DbSelectArea("SE1")
SE1->(DbSetOrder(01))

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

DbSelectArea("FWA")
FWA->(DbSetOrder(02))

DbSelectArea("FWB")
FWB->(DbSetOrder(01))

TRCell():New(oSection, "CONTRATO"  , "", "Contrato"    , "@!"             , 025,, {|| ZC1->ZC1_CODIGO         },,,       ,,,.F.,,,)
TRCell():New(oSection, "LOCAL"     , "", "Local"       , "@!"             , 025,, {|| ZC1->ZC1_LOCCTR         },,,       ,,,.F.,,,)
TRCell():New(oSection, "RAZAO"     , "", "Razão Social", "@!"             , 050,, {|| Left(ZC1->ZC1_RAZSOC,50)},,,       ,,,.F.,,,)
TRCell():New(oSection, "TITULO"    , "", "Núm.Título"  , "@!"             , 015,, {|| SE1->E1_NUM             },,,       ,,,.F.,,,)
TRCell():New(oSection, "VALOR"     , "", "Valor"       , "@E 9,999,999.99", 015,, {|| SE1->E1_VALOR           },,,"RIGHT",,,.F.,,,)
TRCell():New(oSection, "VENCIMENTO", "", "Dt. Vencto." , ""               , 010,, {|| SE1->E1_VENCREA         },,,       ,,,.F.,,,)
TRCell():New(oSection, "DIASATRASO", "", "Dias Atraso" , "@!"             , 010,, {|| nDiasAtr                },,,       ,,,.F.,,,)
TRCell():New(oSection, "CARTEIRA"  , "", "Carteira"    , "@!"             , 010,, {|| " "                     },,,       ,,,.F.,,,)
TRCell():New(oSection, "INCLSERASA", "", "Inc.Serasa"  , ""               , 020,, {|| dDtIncSera              },,,       ,,,.F.,,,)
TRCell():New(oSection, "RETISERASA", "", "Ret.Serasa"  , ""               , 020,, {|| SE1->E1_XDARQSE         },,,       ,,,.F.,,,)
TRCell():New(oSection, "INCLGLOBAL", "", "Inc.Global"  , ""               , 020,, {|| " "                     },,,       ,,,.F.,,,)
TRCell():New(oSection, "RETIGLOBAL", "", "Ret.Global"  , ""               , 020,, {|| " "                     },,,       ,,,.F.,,,)
TRCell():New(oSection, "PAGAMENTO" , "", "Dt.Pgto."    , ""               , 020,, {|| SE1->E1_BAIXA           },,,       ,,,.F.,,,)
TRCell():New(oSection, "OCORRENCIA", "", "Ocorrência"  , "@!"             , 003,, {|| FWB->FWB_CODERR         },,,       ,,,.F.,,,)
TRCell():New(oSection, "DESCOCORRE", "", "Desc.Ocor."  , "@!"             , 010,, {|| " "                     },,,       ,,,.F.,,,)

oReport:SetMeter((cTab)->(RecCount()))
oSection:Init()

(cTab)->(DbGoTop())
while (cTab)->(!Eof())

	If oReport:Cancel()
		Exit
	EndIf

	nDiasAtr   := 0
	dDtIncSera := CtoD("")

	SE1->(DbGoTo((cTab)->RECNOSE1))
	ZC1->(DbSeek(xFilial("ZC1")+SE1->E1_XIDCNT+SE1->E1_XIDLOC))

	nDiasAtr := Date() - SE1->E1_VENCREA
	if nDiasAtr < 0
		nDiasAtr := 0
	endif

	if FWA->(DbSeek(xFilial("FWA")+SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO))
		if FWB->(DbSeek(xFilial("FWB")+FWA->FWA_IDDOC))
			while FWB->FWB_FILIAL+FWB->FWB_IDDOC == FWA->FWA_FILIAL+FWA->FWA_IDDOC .and. FWB->(!Eof())
				if FWB->FWB_OCORR == "3"  // incluído no Serasa
					dDtIncSera := FWB->FWB_DTOCOR
					exit
				endif
				FWB->(DbSkip())
			enddo
		endif
	endif
	
	oReport:IncMeter()
	oSection:PrintLine()
	
	(cTab)->(DbSkip())

enddo

oSection:Finish()

Return