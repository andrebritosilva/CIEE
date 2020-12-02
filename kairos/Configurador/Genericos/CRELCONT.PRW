#Include 'Protheus.ch'
#include "Report.ch"

/*/{Protheus.doc} CRELCONT
Listagem dos contratos e locais do contrato

*** Ao final da implantação do Kairós, este fonte ***
*** pode ser excluído do projeto                  ***

@author danilo.grodzicki
@since 14/05/2020
@version 12.1.25
@type user function
/*/
User Function CRELCONT()

Private cTab
Private oReport
Private oSection1

Private nQtde  := 0
Private aDados := {}

DbSelectArea("ZC0")
ZC0->(DbSetOrder(01))

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

cTab := GetNextAlias()
BeginSql Alias cTab
	%noParser%
    SELECT COUNT(*) AS QTDE
    FROM %TABLE:ZC1% ZC1
    WHERE ZC1.%notDel%
EndSql
(cTab)->(DbSelectArea((cTab)))
(cTab)->(DbGoTop())
if (cTab)->(Eof())
    (cTab)->(DbCloseArea())
   Return Nil
else
	nQtde := (cTab)->QTDE
endif
(cTab)->(DbCloseArea())

cTab := GetNextAlias()
BeginSql Alias cTab
	%noParser%
    SELECT ZC1.ZC1_CODIGO,
	       ZC1.ZC1_LOCCTR,
		   ZC1.ZC1_RAZSOC
    FROM %TABLE:ZC1% ZC1
    WHERE ZC1.%notDel%
    ORDER BY ZC1.ZC1_CODIGO, ZC1.ZC1_LOCCTR
EndSql

(cTab)->(DbSelectArea((cTab)))
(cTab)->(DbGoTop())
if (cTab)->(Eof())
    (cTab)->(DbCloseArea())
   Return Nil
else
	oReport := MontRel()
	oReport:PrintDialog()
endif

Return Nil

/*/{Protheus.doc} MontRel
Listagem dos contratos e locais do contrato
@author danilo.grodzicki
@since 14/05/2020
@version 12.1.25
@type user function
/*/
Static Function MontRel()

Local cTitulo := "Listagem dos Contratos e Locais de Contratos"
Local cDescri := "Esta listagem irá imprimir os Contratos e Locais de Contratos"

oReport := TReport():New("CRELCONT",cTitulo," ",{|oReport| PrintRel(oReport)},cDescri,.T.,,.F.,,.T.)

oReport:oPage:lLandScape := .T.
oReport:oPage:lPortRait  := .F.
oReport:lParamPage       := .F.
oReport:nFontBody        := 6
oReport:SetEdit(.F.)

oSection1 := TRSection():New(oReport,OemToAnsi(""),{"ZC1"},,,,,.T.)

Return(oReport)

/*/{Protheus.doc} PrintRel
Listagem dos contratos e locais do contrato
@author danilo.grodzicki
@since 14/05/2020
@version 12.1.25
@type user function
/*/
Static Function PrintRel(oReport)

Local cTipo := ""

TRCell():New(oSection1,"FILIAL"    ,"","Contrato"             ,"@!",015,,{|| (cTab)->ZC1_CODIGO},,,,,,.F.,,,)
TRCell():New(oSection1,"NUMERO"    ,"","Tipo"                 ,"@!",010,,{|| cTipo             },,,,,,.F.,,,)
TRCell():New(oSection1,"SERIE"     ,"","Razão Social"         ,"@!",150,,{|| ZC0->ZC0_NOME     },,,,,,.F.,,,)
TRCell():New(oSection1,"FORNECE"   ,"","Local"                ,"@!",015,,{|| (cTab)->ZC1_LOCCTR},,,,,,.F.,,,)
TRCell():New(oSection1,"DTEMISSAO" ,"","Razão Social do Local","@!",150,,{|| (cTab)->ZC1_RAZSOC},,,,,,.F.,,,)

oReport:SetMeter(nQtde)
oSection1:Init()

while (cTab)->(!Eof())

	If oReport:Cancel()
		Exit
	EndIf

	oReport:IncMeter()
	
	ZC0->(DbSeek(xFilial("ZC0")+(cTab)->ZC1_CODIGO))

	if ZC0->ZC0_TIPCON == "1"
		cTipo := "Estagio"
	else
		cTipo := "Aprendiz"
	endif

	oSection1:PrintLine()

    (cTab)->(DbSkip())

enddo

oSection1:Finish()                                                      

Return