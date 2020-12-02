#INCLUDE "TOTVS.CH"           
#Include "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

/*/{Protheus.doc} CFINR082
Relatório Apuração IR de Bolsa Auxílio
@author André Brito	
@since 10/07/2020
@version undefined
@type function
/*/

User Function CFINR082(cNumTit,cDescr,dDtaPag,cNomeRel,cDirRel,cTipoTit,cCodTit, lRelatorio)

Local lRet      := .T.
Local cAliAux   := GetNextAlias()
Local cTmpPath 	:= GetTempPath()
Local nTotMov	:= 0
Local cTotGer	:= 0
Local cQuery    := ""
Local dVenc     
Local dDataDe 
Local dDataAte

Private nLin	:= 0
Private nAtuPag	:= 1
Private nTotPag	:= 0
Private cLogo	:= GetSrvProfString("Startpath","")+"\LGMID"+CEMPANT+".PNG" 
Private oFnt9 	:= TFont():New('Arial',,-9,,.F.) 
Private oFntb9 	:= TFont():New('Arial',,-9,,.T.) 
Private oFntb14 := TFont():New('Arial',,-14,,.T.)
Private oPrint	:= NIL
Private cPictVrl:= PESQPICT("RC1","RC1_VALOR")

Default lRelatorio := .T.

If lRelatorio
    cNumTit  := RC1->RC1_NUMTIT
    cDescr   := RC1->RC1_DESCRI
    dDtaPag  := dDataBase
    dDataDe  := RC1->RC1_DTBUSI
    dDataAte := RC1->RC1_DTBUSF
    cNomeRel := "ApuracaoIRBolsaAuxilio"
    cDirRel  := cTmpPath
    cTipoTit := RC1->RC1_TIPO
    cPeriodo := RC1->RC1_COMPET
    cCodTit  := RC1->RC1_CODTIT
    dVenc    := RC1->RC1_VENCTO
EndIf
//Tratamento para impressão do relatório de conferência do IR
If ALLTRIM(RC1->RC1_NATURE)== 'IRF'
	cQuery := " SELECT "  
	cQuery += " RD_XIDFOL, "                                                                                                                                                                                      
	cQuery += " RD_MAT, " 
	cQuery += " RD_XIDCNT, "
	cQuery += " RD_XIDLOC, "
	cQuery += " RD_PERIODO, "
	cQuery += " RD_VALOR "
	cQuery += " FROM "+RetSqlName("SRD")+" SRD "
	cQuery += " WHERE RD_PD = '509'"  
	cQuery += " AND RD_DATPGT BETWEEN '" + Dtos(dDataDe) + "' AND '" + Dtos(dDataAte) + "'"
	//cQuery += " AND RD_PERIODO = '" + cPeriodo + "'"
	cQuery += " AND D_E_L_E_T_=''"
	cQuery += " ORDER BY RD_XIDFOL,RD_MAT "

    cQuery := ChangeQuery(cQuery)

    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliAux,.T.,.T.)

EndIf

(cAliAux)->(dbSelectArea((cAliAux)))

Count To nTotMov

(cAliAux)->(dbGotop())

If (cAliAux)->(!EOF()) 
	
	nTotPag	:= nTotMov / 73
	
	If INT(nTotPag) < nTotPag
		nTotPag:= INT(nTotPag)+1
	EndIf 
	
	FERASE("\spool\"+cNomeRel+".pdf")
	FERASE("\spool\"+cNomeRel+".rel")
	
	oPrint:= FWMSPrinter():New(cNomeRel+".rel",IMP_PDF,.F.,"\spool\",.T.,.F.,,,.T.,.T.,,.T.)			
	oPrint:SetLandscape()
	oPrint:SetResolution(78) 
	oPrint:SetPaperSize(DMPAPER_A4)
	oPrint:SetMargin(40,40,40,40)	
	oPrint:nDevice  := IMP_PDF
    oPrint:cPathPDF := "\spool\"             
	oPrint:lServer  := .T.
	oPrint:lViewPDF := .F.

	CFIN82LR(cNumTit,cDescr,dDtaPag)
	
	WHILE (cAliAux)->(!EOF()) 
		
		If (nLin > 590) 
			oPrint:EndPage()
			oPrint:StartPage()
			nAtuPag+= 1
			CFIN82LR(cNumTit,cDescr,dDtaPag)
		EndIf
		
		//dVenc := STOD(dVenc)
		dVenc := DTOC(RC1->RC1_VENCTO)

		oPrint:Say(nLin,12,(cAliAux)->RD_MAT,oFnt9) //Matricula
		oPrint:Say(nLin,62,ALLTRIM(GetAdvFVal("SRA","RA_NOME" ,XFILIAL("SRA") + (cAliAux)->RD_MAT,1)),oFnt9) //Nome
		oPrint:Say(nLin,222,dVenc,oFnt9) //Vencimento
		oPrint:Say(nLin,277,(cAliAux)->RD_XIDFOL,oFnt9)//ID Folha 
		oPrint:Say(nLin,337,(cAliAux)->RD_PERIODO,oFnt9)//ID Folha 
		oPrint:Say(nLin,397,(cAliAux)->RD_XIDCNT,oFnt9)//Contrato
		oPrint:Say(nLin,457,(cAliAux)->RD_XIDLOC,oFnt9)//Local
		oPrint:Say(nLin,500,TRIM(TRANSFORM((cAliAux)->RD_VALOR,cPictVrl)),oFnt9)//Liq. Receber
		oPrint:Say(nLin,577,TRIM(BuscaValor((cAliAux)->RD_XIDFOL,(cAliAux)->RD_MAT,(cAliAux)->RD_PERIODO,"004")),oFnt9)//Bolsa Aux.
		oPrint:Say(nLin,637,TRIM(BuscaValor((cAliAux)->RD_XIDFOL,(cAliAux)->RD_MAT,(cAliAux)->RD_PERIODO,"277")),oFnt9)//Aux. Trans
        oPrint:Say(nLin,697,TRIM(BuscaValor((cAliAux)->RD_XIDFOL,(cAliAux)->RD_MAT,(cAliAux)->RD_PERIODO,"A05")),oFnt9)//Base IR
		oPrint:Say(nLin,757,TRIM(BuscaValor((cAliAux)->RD_XIDFOL,(cAliAux)->RD_MAT,(cAliAux)->RD_PERIODO,"509")),oFnt9)//Valor IR
		oPrint:Say(nLin,817,TRIM(BuscaValor((cAliAux)->RD_XIDFOL,(cAliAux)->RD_MAT,(cAliAux)->RD_PERIODO,"554")),oFnt9)//Pensao Alim.
		
		cTotGer += TotalIr((cAliAux)->RD_XIDFOL,(cAliAux)->RD_MAT,(cAliAux)->RD_PERIODO,"509")
		nLin+=10
			
		(cAliAux)->(dbSkip())	
		
		If (cAliAux)->(EOF())
			nLin := 590
			oPrint:Box(590,736,600,870)
			oPrint:Line(nLin,798,600,798)
			oPrint:Say(nLin+8,739,"TOTAL (R$)",oFnt9)
			oPrint:SayAlign(nLin-1,801,TRIM(TRANSFORM(cTotGer,cPictVrl)),oFnt9,68,,,1,0)	
			oPrint:SayAlign(nLin-1,11,"Gerado automaticamente pelo Sistema - Protheus",oFnt9,348,,,0,0)
		EndIf
	END
	
	oPrint:EndPage()
	
	oPrint:Print() 
	
	FreeObj(oPrint)
Else

	MsgInfo("Não há dados a serem exibidos", "Aviso")
	
	Return

EndIf
(cAliAux)->(dbCloseArea())

If !lRelatorio
	cNomeRel := cNomeRel+".pdf"
	cDirRel	 := "\spool\"+cNomeRel
	lRet	 := FILE(cDirRel) //VerIfica se gerou o PDF
	
	If lRet
	
		CpyS2T( cDirRel, cTmpPath, .F. )
		
		If File(cTmpPath+cNomeRel)
			ShellExecute("OPEN",cTmpPath+cNomeRel,"","",5)
		Else
			MsgAlert("Não foi possível realizar a cópia do relatório para o diretório:" + CRLF + cTmpPath)
		EndIf
		
	EndIf
EndIf

Return lRet

/*/{Protheus.doc} CFIN82LR
Rotina de impressão do layout do relatório
@author André Brito	
@since 10/07/2020
@version 12.1.25
@type function
/*/

Static function CFIN82LR(cNumTit,cDescr,dDtaPag)

oPrint:Box(10,10,590,870)

oPrint:SayBitmap(01,20,cLogo,080,090)
oPrint:Line(10,10,10,870)
oPrint:Line(10,120,85,120)
oPrint:Line(30,120,30,870)
oPrint:Line(30,220,85,220)

oPrint:SAY(24,380,"RELATÓRIO APURAÇÃO IR DE BOLSA AUXÍLIO",oFntb14)

oPrint:SAY(40,122,"Número:",oFntb9)
oPrint:Say(40,222,cNumTit,oFnt9)
oPrint:Line(42,120,42,870)
oPrint:SAY(50,122,"Descritivo:",oFntb9)
oPrint:Say(50,222,cDescr,oFnt9)
oPrint:Line(52,120,52,870)
oPrint:SAY(60,122,"Data de Pagamento:",oFntb9)
oPrint:Say(60,222,DTOC(dDtaPag),oFnt9)
oPrint:Line(62,120,62,870)
oPrint:SAY(70,122,"Data da Integração:",oFntb9)
oPrint:Say(70,222,DTOC(DATE()),oFnt9)
oPrint:Line(72,120,72,870)
oPrint:SAY(80,122,"Página:",oFntb9)
oPrint:Say(80,222,CVALTOCHAR(nAtuPag) +  " de " + CVALTOCHAR(nTotPag) ,oFnt9)

nLin:= 85
oPrint:Line(nLin,10,nLin,870)
oPrint:Line(nLin,61,590,61)
oPrint:Line(nLin,220,590,220)
oPrint:Line(nLin,275,590,275)
oPrint:Line(nLin,335,590,335)
oPrint:Line(nLin,395,590,395)
oPrint:Line(nLin,455,590,455)
oPrint:Line(nLin,515,590,515)
oPrint:Line(nLin,575,590,575)
oPrint:Line(nLin,635,590,635)
oPrint:Line(nLin,695,590,695)
oPrint:Line(nLin,755,590,755)
oPrint:Line(nLin,815,590,815)
oPrint:SAY(nLin+9,11,"Matricula",oFntb9)
oPrint:SAY(nLin+9,61,"Nome",oFntb9)
oPrint:SAY(nLin+9,220,"Vencimento")
oPrint:SAY(nLin+9,275,"ID Folha",oFntb9)
oPrint:SAY(nLin+9,335,"Competencia",oFntb9)
oPrint:SAY(nLin+9,395,"Contrato",oFntb9)
oPrint:SAY(nLin+9,455,"Local",oFntb9)
oPrint:SAY(nLin+9,515,"Liq. Receber",oFntb9)
oPrint:SAY(nLin+9,575,"Bolsa Aux.",oFntb9)
oPrint:SAY(nLin+9,635,"Aux. Trans.",oFntb9)
oPrint:SAY(nLin+9,695,"Base IR",oFntb9)
oPrint:SAY(nLin+9,755,"Valor IR",oFntb9)
oPrint:SAY(nLin+9,815,"Pensao Alim.",oFntb9)

oPrint:Line(nLin+12,10,nLin+12,870)

nLin:= nLin+22

Return

/*/{Protheus.doc} BuscaValor
//TODO Retorna valor de uma verba dos movimentos da folha
@author andre.brito
@since 11/07/2020
@version 1.0
@Return ${Return}, ${Return_description}
@param cPerg, characters, descricao
@type function
/*/

Static Function BuscaValor(cIDFOL,cMatr,cCompet,cVerba)

local nRet   := 0
local cAlias := GetNextAlias()

BeginSql Alias cAlias

	SELECT                                                                                                                                                               
		SUM(RC_VALOR) AS VALOR
	FROM 
		SRC010 SRC
	WHERE  
		SRC.%notDel%  AND
		RC_FILIAL=%xfilial:SRC% AND
		RC_XIDFOL=%Exp:cIDFOL% AND
		RC_MAT=%Exp:cMatr% AND
		RC_PERIODO=%Exp:cCompet% AND
		RC_PD=%Exp:cVerba% 

EndSql

If (cAlias)->(!EOF())
	nRet := (cAlias)->VALOR	
EndIf
	
(cAlias)->(dbCloseArea())

Return(TRANSFORM(nRet, "@E 999,999.99"))

/*/{Protheus.doc} TotalIr
//Retorna valor total de IR
@author andre.brito
@since 11/07/2020
@version 1.0
@Return ${Return}, ${Return_description}
@param cPerg, characters, descricao
@type function
/*/

Static Function TotalIr(cIDFOL,cMatr,cCompet,cVerba)

local nRet   := 0
local cAlias := GetNextAlias()

BeginSql Alias cAlias

	SELECT                                                                                                                                                               
		SUM(RC_VALOR) AS VALOR
	FROM 
		SRC010 SRC
	WHERE  
		SRC.%notDel%  AND
		RC_FILIAL=%xfilial:SRC% AND
		RC_XIDFOL=%Exp:cIDFOL% AND
		RC_MAT=%Exp:cMatr% AND
		RC_PERIODO=%Exp:cCompet% AND
		RC_PD=%Exp:cVerba% 

EndSql

If (cAlias)->(!EOF())
	nRet := (cAlias)->VALOR	
EndIf
	
(cAlias)->(dbCloseArea())

Return nRet