#INCLUDE "TOTVS.CH"
#INCLUDE "RWMAKE.CH"

/*/{Protheus.doc} CINTK05
//TODO Descrição auto-gerada.
@author Milton J.dos Santos
@since 21/05/2020
@version 1.0
@return ${return}, ${return_description}
/*/

User Function CINTK15
Local aPergs	:= {}
Local aRet		:= {}
Local dGetRef 	:= dDataBase
Local cTab		:= GetNextAlias()
Local oStatus

Private aStatus  := {}
Private aLegenda := {}

aAdd( aLegenda, { "1","Pendente de Integração"	,"BR_AMARELO" 	} )
aAdd( aLegenda, { "2","Integração com sucesso "	,"BR_VERDE"	 	} )
aAdd( aLegenda, { "3","Falha na Integração   "	,"BR_AZUL"	 	} )

aAdd( aPergs ,{1,"Integração De  : ",dGetRef	,,'.T.'				,,'.T.',50,.F.})
aAdd( aPergs ,{1,"Integração Ate : ",dGetRef	,,'.T.'				,,'.T.',50,.F.})

If ! ParamBox(aPergs ,"Status de Faturamento",aRet)
	RETURN
EndIf

cQuery := " SELECT ZC6_LOTE, ZC6_STATUS, ZC6_DTINTE, ZC6_DATVEN,  "	+ CRLF
cQuery += "	SUM(ZC6_QTDE)	AS QTDE "								+ CRLF
cQuery += "	FROM " + RetSQLNAME("ZC6") + ' ZC6 '					+ CRLF
cQuery += "	WHERE	ZC6.D_E_L_E_T_ = ' '"							+ CRLF
cQuery += "		AND	ZC6_FILIAL = '" + xFilial("ZC6")	+ "'"		+ CRLF
cQuery += "		AND ZC6_DTINTE >= '" + DtoS( aRet[1] )	+ "'"		+ CRLF
cQuery += "		AND ZC6_DTINTE <= '" + DtoS( aRet[2] )	+ "'"		+ CRLF
cQuery += "	GROUP BY ZC6_LOTE, ZC6_STATUS, ZC6_DTINTE, ZC6_DATVEN "	+ CRLF

dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),cTab, .F., .T.)

(cTab)->(DbGoTop())

If ((cTab)->(EOF()))

	Alert( "Nao encontrou registros no periodo selecionado!")
	(cTab)->(dbCloseArea())
	Return
Else

	DbSelectArea(cTab)
	Do While ! (cTab)->(Eof())
		cDescr := Space(22)
		nPos := aScan( aLegenda, { |x| x[1] == (cTab)->(ZC6_STATUS) })
		If nPos > 0
			cDescr := aLegenda[ nPos, 2]
		Endif

		aAdd( aStatus, { ZC6_STATUS, ZC6_LOTE, ZC6_STATUS, cDescr, StoD( ZC6_DTINTE ), StoD( ZC6_DATVEN ) } )

		(cTab)->(dbSkip())
	Enddo

Endif	

(cTab)->(dbCloseArea())

DEFINE MSDIALOG oDlg TITLE "Status de Faturamento " From 000,000 to 380,520 COLORS 0, 16777215 PIXEL
				
@ 010,009 SAY oSay PROMPT "Integração De :" SIZE 073,007 OF oDlg COLORS 0, 16777215 PIXEL
@ 010,064 MSGET oGet VAR  aRet[1] SIZE 045,011 OF oDlg COLORS 0, 16777215 PIXEL WHEN .F.

@ 030,009 SAY oSay PROMPT "Integração Ate:" SIZE 073,007 OF oDlg COLORS 0, 16777215 PIXEL
@ 030,064 MSGET oGet VAR aRet[2] SIZE 045,011 OF oDlg COLORS 0, 16777215 PIXEL WHEN .F.

@ 060,005 LISTBOX oStatus Var cModelo FIELDS HEADER  ; 
	OemToAnsi("Legenda")	,;
	OemToAnsi("Lote")		,;
	OemToAnsi("Status")		,;
    OemToAnsi("Descricao")	,;
 	OemToAnsi("Data")		,;
	OemToAnsi("Vencimento")      ColSizes 050, 050, 020, 050, 040, 040 SIZE 240,070 ON DBLCLICK () PIXEL OF oDlg 
	oStatus:SetArray(aStatus)
	oStatus:bLine:={ ||{ Legenda( oStatus:nAT,1 ), aStatus[oStatus:nAT,2],aStatus[oStatus:nAT,3],aStatus[oStatus:nAT,4],aStatus[oStatus:nAT,5],  aStatus[oStatus:nAT,6] }}
	oStatus:Refresh()

@ 140,020 SAY    oSay PROMPT  aLegenda[ 1,2 ] SIZE 073,007 OF oDlg COLORS 0, 16777215 PIXEL
@ 140,010 BITMAP oBmp RESNAME aLegenda[ 1,3 ] OF oDlg SIZE 60,30 NOBORDER PIXEL

@ 150,020 SAY oSay PROMPT     aLegenda[ 2,2 ] SIZE 073,007 OF oDlg COLORS 0, 16777215 PIXEL
@ 150,010 BITMAP oBmp RESNAME aLegenda[ 2,3 ] OF oDlg SIZE 60,30 NOBORDER PIXEL

@ 160,020 SAY oSay PROMPT     aLegenda[ 3,2 ] SIZE 073,007 OF oDlg COLORS 0, 16777215 PIXEL
@ 160,010 BITMAP oBmp RESNAME aLegenda[ 3,3 ] OF oDlg SIZE 60,30 NOBORDER PIXEL

@ 160,203 BUTTON oButtonOK PROMPT "OK" SIZE 034,013 OF oDlg PIXEL ACTION(oDlg:End())

ACTIVATE MSDIALOG oDlg CENTERED

Return .T.

Static Function Legenda ( _nLinha, _cColuna )
Local nPos := 0
Local oRet

If _nLinha > Len( aStatus )
	Return NIL
Else
	nPos := aScan( aLegenda, { |x| x[1] == aStatus[_nLinha,_cColuna] })
Endif
If nPos == 0
	oRet := LoaDBitmap( GetResources(), "BR_BRANCO"		)
Else
	oRet := LoaDBitmap( GetResources(), aLegenda[nPos,3]	)
Endif
Return( oRet )
