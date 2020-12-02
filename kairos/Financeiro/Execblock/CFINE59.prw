#INCLUDE 'Protheus.ch'
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"


/*/{Protheus.doc} CFINE59
	Função responsavel por gerar tela de processamento do relatorio analitico de validação bancaria
@author felipe ortega
@since 16/11/2020
@version 1.0
@return ${return}, ${return_description}
@param cNumTit, characters, descricao
@param cFornece, characters, descricao
@param cLoja, characters, descricao
@param dDataPgt, date, descricao
@type function
/*/
User function CFINE59(cNumTit, cFornece, cLoja, dDataPgt)

    FWMsgRun(,{|| CFIN5901(@cNumTit, @cFornece, @cLoja, @dDataPgt)}, , "Processando relatorio...")

Return

/*/{Protheus.doc} CFIN5901
	Processa relatorio de validação bancaria
@author felipe ortega
@since 16/11/2020
@version 1.0
@return ${return}, ${return_description}
@param cNumTit, characters, descricao
@param cFornece, characters, descricao
@param cLoja, characters, descricao
@param dDataPgt, date, descricao
@type function
/*/
static function CFIN5901(cNumTit, cFornece, cLoja, dDataPgt)

	Local nTotGer	:= 0
	Local cQuery    := ""
	local cNomeRel  := "CONFERE VALIDA CONTA"
	Local cTmpPath 	:= GetTempPath()
	local cDirRel   := "\spool\" + cNomeRel
	local cTab	 	:= GetNextAlias()
	local lRet		:= .f.
    local nValor    := 0.01

	Private nLin	:= 0
	Private nAtuPag	:= 1
	Private nTotPag	:= 0
	Private cLogo	:= GetSrvProfString("Startpath","")+"\LGMID"+CEMPANT+".PNG"
	Private oFnt9 	:= TFont():New('Arial',,-9,,.F.)
	Private oFntb9 	:= TFont():New('Arial',,-9,,.T.)
	Private oFntb14 := TFont():New('Arial',,-14,,.T.)
	Private oPrint	:= NIL
	Private cPictVrl:= PESQPICT("RC1","RC1_VALOR")
	Private lImpIrf := .F.

	default lJob	:= .f.

	FERASE("\spool\"+cNomeRel+".pdf")
	FERASE("\spool\"+cNomeRel+".rel")

	oPrint:= FWMSPrinter():New(cNomeRel+".rel",IMP_PDF,.F.,"\spool\",.t.,.F.,,,.T.,.T.,,.T.)
	oPrint:SetLandscape()
	oPrint:SetResolution(78)
	oPrint:SetPaperSize(DMPAPER_A4)
	oPrint:SetMargin(40,40,40,40)
	oPrint:nDevice  := IMP_PDF
	oPrint:cPathPDF := "\spool\"
	oPrint:lServer  := .T.
	oPrint:lViewPDF := .F.
	oPrint:StartPage()
    nTotPag++

	cQuery += "SELECT DISTINCT RA.RA_MAT MATRICULA, RA.RA_NOME NOME, RA.RA_BCDEPSA BANAGE, RA.RA_CTDEPSA CONTA, '0.01' VALOR, CONCAT(CONCAT(RTRIM(RA.RA_XIDCONT), '/'), RTRIM(RA.RA_XIDLOCT)) CONTRATO, " + CRLF
    cQuery += " RA.RA_XDIGAG DIGAGENCIA, RA.RA_XDIGCON DIGCONTA " + CRLF
	cQuery += "FROM " + RetSqlName("SRA") + " RA " + CRLF
	cQuery += "WHERE RA.RA_FILIAL = '" + xFilial("SRA") + "' " + CRLF
	cQuery += " AND RA.RA_XTITVLD = '" + cNumTit + "' " + CRLF
	cQuery += " AND RA.D_E_L_E_T_ = ' ' " + CRLF
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cTab,.T.,.T.)

	if (cTab)->(!EOF())
		
		CFIN5902(@cFornece, @cLoja, @dDataPgt)

		While (cTab)->(!EOF())

			If (nLin > 590)
				oPrint:EndPage()
				oPrint:StartPage()
				nAtuPag++
                nTotPag++
				CFIN5902(@cFornece, @cLoja, @dDataPgt)
			Endif

			oPrint:Say(nLin,11,(cTab)->MATRICULA,oFnt9)
			oPrint:Say(nLin,91,(cTab)->NOME,oFnt9)
			oPrint:Say(nLin,301,TRANSFORM((cTab)->BANAGE, "@R 999/99999"),oFnt9)
            oPrint:Say(nLin,401,alltrim((cTab)->DIGAGENCIA),oFnt9)
			oPrint:Say(nLin,521,alltrim((cTab)->CONTA),oFnt9)
			oPrint:Say(nLin,601,alltrim((cTab)->DIGCONTA),oFnt9)
			oPrint:Say(nLin,694,TRIM((cTab)->VALOR),oFnt9)
			oPrint:Say(nLin,799,TRIM((cTab)->CONTRATO),oFnt9)

			nTotGer += nValor
			nLin += 10

			(cTab)->(dbSkip())

			If (cTab)->(Eof())
				nLin := 590
				oPrint:Box(590,736,600,870)
				oPrint:Line(nLin,798,600,798)
				oPrint:Say(nLin+8,739,"TOTAL (R$)",oFnt9)
				oPrint:SayAlign(nLin-1,801,TRIM(TRANSFORM(nTotGer,cPictVrl)),oFnt9,68,,,1,0)
				oPrint:SayAlign(nLin-1,11,"Gerado automaticamente pelo Sistema - Protheus",oFnt9,348,,,0,0)
			EndIf

		Enddo

		oPrint:EndPage()
		oPrint:Print()
		FreeObj(oPrint)

		sleep(2000)

		cNomeRel := cNomeRel + ".pdf"
		cDirRel := "\spool\" + cNomeRel
		lRet := FILE(cDirRel) //Verifica se gerou o PDF

		CpyS2T(cDirRel, cTmpPath , .F. )

		if !lJob

			ShellExecute("OPEN",cTmpPath+cNomeRel,"","",5)

		endif

	else

		if !lJob

			msgInfo("Nenhum registro encontrado")

		endif

	endif

Return lRet

/*/{Protheus.doc} CFIN5902
	Processa cabeçalho do relatorio analitico de validação bancaria
@author felipe ortega
@since 16/11/2020
@version 1.0
@return ${return}, ${return_description}
@param cFornece, characters, descricao
@param cLoja, characters, descricao
@param dDataPgt, date, descricao
@type function
/*/
Static function CFIN5902(cFornece, cLoja, dDataPgt)

	oPrint:Box(10,10,590,870)

	oPrint:SayBitmap(01,20,cLogo,080,090)
	oPrint:Line(10,10,10,870)
	oPrint:Line(10,120,85,120)
	oPrint:Line(30,120,30,870)

	dbSelectArea("SA2")

	SA2->(DbSetOrder(1))

	if SA2->(msseek(xFilial("SA2") + padr(alltrim(cFornece), tamsx3("A2_COD")[1]) + alltrim(cLoja)))

		oPrint:SAY(24,380,"RELATÓRIO ANALÍTICO - VALIDAÇÃO DE CONTA",oFntb14)    

		oPrint:SAY(40,122,"Fornecedor:",oFntb9)
		oPrint:Say(40,222,alltrim(SA2->A2_NOME),oFnt9)
		oPrint:Line(42,120,42,870)
		oPrint:SAY(50,122,"Data de Pagamento:",oFntb9)
		oPrint:Say(50,222,DTOC(dDataPgt),oFnt9)
		oPrint:Line(52,120,52,870)
		oPrint:SAY(60,122,"Página:",oFntb9)
		oPrint:Say(60,222,CVALTOCHAR(nAtuPag) +  " de " + CVALTOCHAR(nTotPag),oFnt9)
		oPrint:Line(62,120,62,870)

		nLin := 85
		oPrint:Line(nLin,10,nLin,870)
		oPrint:Line(nLin,90,590,90)
		oPrint:Line(nLin,300,590,300)
		oPrint:Line(nLin,400,590,400)
		oPrint:Line(nLin,520,590,520)
		oPrint:Line(nLin,600,590,600)
		oPrint:Line(nLin,690,590,690)
		oPrint:Line(nLin,798,590,798)


		//oPrint:Line(nLin,736,590,736)
		//oPrint:Line(nLin,798,590,798)



		oPrint:SAY(nLin+9,11,"Matricula",oFntb9)
		oPrint:SAY(nLin+9,91,"Nome",oFntb9)
		oPrint:SAY(nLin+9,301,"Banco/Agencia", oFntb9)
		oPrint:SAY(nLin+9,401,"Dig. Agencia",oFntb9)
		oPrint:SAY(nLin+9,521,"Conta", oFntb9)	//	"Total de Bolsas", oFntb9)
		oPrint:SAY(nLin+9,601,"Dig. Conta", oFntb9)	//	"Tot.Aux.Transp.", oFntb9)
		oPrint:SAY(nLin+9,691,"Valor", oFntb9)	//	"IR e Pensão", oFntb9)
		oPrint:SAY(nLin+9,799,"Contrato\Local", oFntb9)	//	"CI Devida", oFntb9)
		oPrint:Line(nLin+12,10,nLin+12,870)

		nLin += 22

	endif

Return

