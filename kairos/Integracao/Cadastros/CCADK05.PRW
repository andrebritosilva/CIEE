#Include 'Protheus.ch'
#Include 'Fwmvcdef.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} CCADK05
Repasses
@author
@since 21/07/2020
@version 12.1.25
@type user function
/*/
User Function CCADK05()

Local oBrowse := Nil

oBrowse := FwMBrowse():New()
oBrowse:SetAlias('ZCC')
oBrowse:SetDescription('Repasses')
oBrowse:AddLegend('ZCC_STATUS == "1"', 'BR_AMARELO' , 'Aberto'            )
oBrowse:AddLegend('ZCC_STATUS == "2"', 'BR_LARANJA' , 'Em aprovação Fluig')
oBrowse:AddLegend('ZCC_STATUS == "3"', 'BR_VERMELHO', 'Reprovado'         )
oBrowse:AddLegend('ZCC_STATUS == "4"', 'BR_VERDE'   , 'Aprovado'          )
oBrowse:AddLegend("ZCC_STATUS=='5'", "BR_PRETO"    , "Erro Integracao"    )
oBrowse:AddLegend("ZCC_STATUS=='6'", "BR_AZUL"     , "Integrado"          )

oBrowse:Activate()

Return

/*/{Protheus.doc} MenuDef
Repasses
@author
@since 21/07/2020
@version 12.1.25
@type static function
/*/
Static Function MenuDef

Local aRotina := {}

Add Option aRotina Title 'Visualizar'                     Action "U_CCK05VIS" Operation 2 ACCESS 0
Add Option aRotina Title 'Gerar Repasse      '            Action "U_CCK05IMP" Operation 3 Access 0
Add Option aRotina Title 'Estorna Competência'            Action "U_CCK05EST" Operation 1 Access 0
Add Option aRotina Title 'Solicita Aprovação (FLUIG)'     Action "U_CCK05FLG" Operation 1 Access 0
Add Option aRotina Title 'Relat. Resumo FRM'              Action "U_CCADKR5"  Operation 1 Access 0
Add Option aRotina Title 'Relatorio Analitico FRM'        Action "U_CRELK05A" Operation 1 Access 0
Add Option aRotina Title 'Valor Unitario'             	  Action "U_CCAD_VU"  Operation 1 Access 0
Add Option aRotina Title 'ICN Receber - Gera Titulo'      Action "U_COMP_REC" Operation 1 Access 0
Add Option aRotina Title 'ICN Receber - Compensa Título'  Action "U_CCK05CMP" Operation 1 Access 0
Add Option aRotina Title 'Conhecimento'                   Action "MsDocument" Operation 6 Access 0
Add Option aRotina Title 'Legenda'                        Action "U_CCK05LEG" Operation 6 Access 0
Add Option aRotina Title 'Alterar'                        Action "U_CCAD_ALT" Operation 4 Access 0

Return(aRotina)

/*/{Protheus.doc} ModelDef
Repasses
@author
@since 21/07/2020
@version 12.1.25
@type static function
/*/
Static Function ModelDef()

Local oModel   := Nil
Local oStruZCC := FWFormStruct(1,'ZCC',/*bAvalCampo*/,/*lViewUsado*/)

oModel := MPFormModel():New('ZCC001MO',/*bPreValidacao*/,{ |oModel| ValModelo( oModel ) }/*bPosValidacao*/,/*bCommit*/,/*bCancel*/ )

oModel:AddFields('ZCCMASTER',/*cOwner*/,oStruZCC,/*bPreValidacao*/,/*bPosValidacao*/,/*bCarga*/)
oModel:SetDescription('Repasses')

oModel:SetPrimaryKey({})

Return(oModel)

/*/{Protheus.doc} ViewDef
Repasses
@author
@since 21/07/2020
@version 12.1.25
@type static function
/*/
Static Function ViewDef()

Local oView    := Nil
Local oModel   := FWLoadModel('CCADK05')
Local oStruZCC := FWFormStruct(2,'ZCC')

oView := FWFormView():New()

oView:SetModel(oModel)
oView:AddField('VIEW_ZCC', oStruZCC, 'ZCCMASTER')

oView:CreateHorizontalBox('TELA', 100)
oView:SetOwnerView('VIEW_ZCC', 'TELA')

Return(oView)

/*/{Protheus.doc} CCK05LEG
Legenda dos Repasses
@author
@since 21/07/2020
@version 12.1.25
@type user function
/*/
User Function CCK05LEG()

BrwLegenda("Status Repasses", "Legenda", {;
										 {"BR_AMARELO" , OemToAnsi("Aberto"          )},;
										 {"BR_LARANJA" , OemToAnsi("Enviado ao Fluig")},;
										 {"BR_VERMELHO", OemToAnsi("Reprovado"       )},;
										 {"BR_VERDE"   , OemToAnsi("Aprovado"        )},;
										 {"BR_PRETO"   , OemToAnsi("Erro Integracao" )},;
										 {"BR_AZUL"    , OemToAnsi("Integrado"       )}})

Return Nil



User Function CCAD_IC()  // Importa competência
	
//	Local cTab

	LOCAL oScroll 	:= NIL

	Local oOk      	:= LoadBitMap(GetResources(), "BR_AZUL") 		// LoadBitmap( GetResources(), "LBOK" )   //CHECKED    //LBOK  //LBTIK
	Local oNo      	:= LoadBitMap(GetResources(), "BR_VERMELHO") 	// LoadBitmap( GetResources(), "LBNO" ) //UNCHECKED  //LBNO
	LOCAL nTop 		:= 5
	LOCAL n 		:= 0
	LOCAL cGet 		:= ""
	LOCAL cPict 	:= ""
	LOCAL cVar 		:= ""
	
	Local oLbx1 	:= NIL
	Local aTitulo 	:= {}
	Local lMark    	:= .F.
	Local nOpcA    	:= 0

	PRIVATE bGet 	:= NIL
	PRIVATE oGet 	:= NIL
	PRIVATE oDlg 	:= NIL
	PRIVATE cTitulo := "REPASSE"
	PRIVATE aSay 	:= {}
	PRIVATE cGetNUM := Space(06)

	cGetNUM	:= ZCC->ZCC_IDREP

	If ZCD->(dBSeek(xFilial('ZCD')+ZCC->ZCC_IDREP))

		While 	!ZCD->(Eof()) .And.;
	 		ZCD->ZCD_FILIAL+ZCD->ZCD_IDREP = ZCC->ZCC_FILIAL+ZCC->ZCC_IDREP

			SA1->(dBSetOrder(1))
			SA1->(dBSeek(xFilial("SA1")+ZCD->ZCD_CLIENT+ZCD->ZCD_LOJA))
			// lMark,;
			aAdd(aTitulo,{	lMark,;
							Alltrim(STR(ZCD->ZCD_QTDE)) ,;
							Transform(ZCD->ZCD_VALOR	,"@E 99,999,999,999.99"),;
							Transform(ZCD->ZCD_VALTOT	,"@E 99,999,999,999.99"),;
							ZCD->ZCD_CLIENT,;
							ZCD->ZCD_LOJA,;
							SA1->A1_NREDUZ,;
							ZCD->ZCD_TIPTIT,;
							ZCD->ZCD_UNREP,;
							DTOC(ZCD->ZCD_VENCTO),;
							DTOC(ZCD->ZCD_EMISSA),;
							ZCD->ZCD_RAZAOS,;
							ZCD->ZCD_CODCTR,;
							ZCD->ZCD_IDLCTR})


			ZCD->(dBSkip())

		EndDo

	Else

		// lMark,;
		aAdd(aTitulo,{	lMark,;
						"",;
						"",;
						"",;
						"",;
						"",;
						"",;
						"",;
						"",;
						"",;
						"",;
						"",;
						"",;
						""})

	EndIf

	aSize := MsAdvSize(.F.)
	DEFINE MSDIALOG oDlg TITLE cTitulo FROM aSize[7],0 To aSize[6],aSize[5]	OF oDlg PIXEL

	@ 033,002 TO aSize[4],0192 LABEL "Repasse - Sintético"  		OF oDlg PIXEL // 219
	@ 033,195 TO aSize[4],aSize[6] LABEL "Repasse - Analítico"   	OF oDlg PIXEL // 348
	
	//scroll box Sintêtico
	@ 042,006 SCROLLBOX oScroll HORIZONTAL VERTICAL SIZE aSize[4]-46,182 OF oDlg BORDER
	oDlg:lMaximized := .T. //Maximiza a janela
	oDlg:lCentered 	:= .T. // Centraliza a tela

	If !ZCC->(Eof())

		aAdd(aSay,{"Competencia "	,"C",06,0,"ZCC->ZCC_COMPET" 	,"@!"})
		aAdd(aSay,{"ID Repasse  "  	,"C",09,0,"ZCC->ZCC_IDREP "  	,"@!"})
		aAdd(aSay,{"Tipo Repasse"   ,"C",03,0,"ZCC->ZCC_TIPREP"		,"@!"})
		aAdd(aSay,{"Prefixo Tit."  	,"C",03,0,"ZCC->ZCC_PFXREP"		,"@!"})
		aAdd(aSay,{"Vencto Repas"  	,"D",08,0,"ZCC->ZCC_VENCTO" 	,"99/99/9999"})
		aAdd(aSay,{"Emissao Rep."  	,"D",08,0,"ZCC->ZCC_EMISSA" 	,"99/99/9999"})
		aAdd(aSay,{"Val. Total  "  	,"N",16,2,"ZCC->ZCC_VALTIT" 	,"@E 9,999,999,999,999.99"})
		aAdd(aSay,{"Fornecedor  "	,"C",06,0,"ZCC->ZCC_FORNRE"  	,"@!"})
		aAdd(aSay,{"Loja        " 	,"C",02,0,"ZCC->ZCC_LOJA  " 	,"@!"})
		aAdd(aSay,{"Tipo Titulo "	,"C",03,0,"ZCC->ZCC_TIPTIT"  	,"@!"})
		aAdd(aSay,{"Produto     " 	,"C",15,0,"ZCC->ZCC_PRODRE" 	,"@!"})
		aAdd(aSay,{"Documento	"	,"C",09,0,"ZCC->ZCC_NUMDOC"		,"@!"})
		aAdd(aSay,{"Serie		"	,"C",03,0,"ZCC->ZCC_SERIE"		,"@!"})
		aAdd(aSay,{"ID Fluig	"	,"C",08,0,"ZCC->ZCC_NUMFLG" 	,"@!"})
		

		For n:=1 TO Len(aSay)
			bGet := &("{|| '"+aSay[n,1]+"'}")
			cVar := aSay[n,5]
			cGet  := "{|u| iif(PCount()>0,"+cVar+":=u,"+cVar+")}"
			cPict := aSay[n,6]
			TSay():New(nTop,5,bGet,oScroll,,,.F.,.F.,.F.,.T.,,,GetTextWidth(0,Trim(aSay[n,1])),15,.F.,.F.,.F.,.F.,.F.)
			oGet:=TGet():New(nTop-2,40,&cGet,oScroll,,7,cPict,,,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,(cVar),,,,.T.)
			nTop+=11
		Next n

		//list box Analíticos

		@ 046,199 LISTBOX oLbx1 FIELDS HEADER ;
		" ", "Qtd. Apr.", "Valor Faturamento", "Valor Repasse", ;
		"Cliente", "Loja", "Descrição Resumida", "Tipo Tit.", "Unid.", "Vencto.", "Emissão", "Razão Social", "Contrato", "ID Local Contrato" ;
		SIZE 472,240 OF oDlg PIXEL 

		oLbx1:SetArray( aTitulo )

		oLbx1:bLine := {|| {Iif(aTitulo[oLbx1:nAt,1],oOk,oNo),;
								aTitulo[oLbx1:nAt,2],;
								aTitulo[oLbx1:nAt,3],;
								aTitulo[oLbx1:nAt,4],;
								aTitulo[oLbx1:nAt,5],;
								aTitulo[oLbx1:nAt,6],;
								aTitulo[oLbx1:nAt,7],;
								aTitulo[oLbx1:nAt,8],;
								aTitulo[oLbx1:nAt,9],;
								aTitulo[oLbx1:nAt,10],;
								aTitulo[oLbx1:nAt,11],;
								aTitulo[oLbx1:nAt,12],;
								aTitulo[oLbx1:nAt,13],;
								aTitulo[oLbx1:nAt,14]}}

	EndIf

	oDlg:LCENTERED = .T.
	ACTIVATE MSDIALOG oDlg CENTER ON INIT EnchoiceBar(oDlg,{||nOpcA:=1,oDlg:End()},{||oDlg:End()})

Return

/*/{Protheus.doc} CCK05IMP
Importa Repasses
@author
@since 21/07/2020
@version 12.1.25
@type user function
/*/
User Function CCK05IMP()

Local nI
Local cTab
Local cCndQyr

Local aIdRep   := {}
Local cAutuPg  := space(15)
Local cAutuRc  := space(15)
Local cCnpjBB  := AllTrim(GetMv('CI_CNPJBB'))
Local cCnpjCX  := AllTrim(GetMv('CI_CNPJCX'))
Local cCNPJFRM := AllTrim(GetMv('CI_CNPJFRM'))
Local cNumTit  := ""
Local cCNPJAUT := ""
Local aSA1     := {}
Local _cMsg    := "Repasse gerado com sucesso."
Local aTitRec  := {}

Private aRet   := {}
Private aPergs := {}
Private lMsErroAuto := .F.

//aAdd(aPergs ,{2,"Tipo Repasse ?","1 - FRM",{"1 - FRM","2 - Autônomo","3 - Empresas"},60,"",.F.})
aAdd(aPergs ,{2,"Tipo Repasse ?","1 - FRM",{"1 - FRM","2 - ICN Pagar","3 - ICN Receber Prov.","4 - Empresas"},60,"",.F.})
aAdd(aPergs ,{1,"Competência (MMAAAA) ?",Space(6),"@!",'','','.T.',40,.F.})

If ParamBox(aPergs ,"Parametros",aRet)

	If SubStr(aRet[1],1,1) == "1"  // FRM

		If Empty(aRet[2])
			MsgInfo("Informe uma Competência.", "ATENÇÃO")
			Return
		endif

		ZCC->(dBSetOrder(2))
		If ZCC->(dBSeek(xFilial('ZCC')+aRet[2]+"FRM"))
			MsgInfo("Competência já importada.", "ATENÇÃO")
			Return
		endif

		// LOCALIZA CNPJ FRM
		SA2->(dBSetOrder(03))
		If !SA2->(dBSeek(xFilial('SA2')+cCNPJFRM))
			MsgInfo("CNPJ informado no parâmetro CI_CNPJFRM, não encontrado na tabela SA2", "ATENÇÃO")
			Return
		endif

		cTab := GetNextAlias()
		BeginSql alias cTab
		
		SELECT E1_PREFIXO, 
			   E1_NUM,
			   E1_VALOR,
		       E1_CLIENTE, 
		       E1_LOJA, 
		       E1_NOMCLI,
		       E1_TIPO, 
		       E1_XIDFATU, 
		       ZC6_IDFATU, 
		       ZC6_COMPET, 
		       Count(ZC6_IDFATU) QTDE, 
		       ZC6_LOCCON, 
		       ZC6_IDCONT, 
		       ZC6_VALOR, 
		       ZC6_VLRTOT        VLRTOT, 
		       Sum(ZC6_VLRTOT)   TOTAL, 
		       ZC0_NOME 
		FROM   %table:ZC6%  ZC6 
		       JOIN %table:ZC5%  ZC5 
		         ON ZC5_FILIAL = ZC6_FILIAL 
		            AND ZC5_IDFATU = ZC6_IDFATU 
		            AND ZC5.D_E_L_E_T_ = ' ' 
		       JOIN %table:SE1%  SE1 
		         ON E1_FILORIG = ZC6_FILIAL 
		            AND E1_XIDFATU = ZC6_IDFATU 
		            AND E1_PEDIDO <> ' ' 
		            AND SE1.D_E_L_E_T_ = ' ' 
		       JOIN %table:SA1%  SA1 
		         ON A1_FILIAL = E1_FILIAL 
		            AND A1_COD = E1_CLIENTE 
		            AND A1_LOJA = E1_LOJA 
		            AND SA1.D_E_L_E_T_ = ' ' 
		       JOIN %table:ZC0%  ZC0 
		         ON ZC0_CODIGO = ZC6_IDCONT 
		            AND ZC0.D_E_L_E_T_ = ' ' 
		       JOIN %table:SRA%  SRA 
		         ON RA_FILIAL = ZC6_FILIAL 
		            AND RA_CIC = ZC6_CPFEST 
		WHERE  ZC6_FILIAL = %xFilial:ZC6%
		       AND ZC6_COMPET = %exp:aRet[2]% 
		       AND ZC6_GERZC5 = 'S' 
		       AND ZC6.D_E_L_E_T_ = ' ' 
		       AND ZC0_TIPCON = '2' 
		       AND ( Substring(RA_ADMISSA, 1, 6) <= %exp:SubStr(aRet[2],3,4) + SubStr(aRet[2],1,2)%
		              OR Substring(RA_DEMISSA, 1, 6) >= %exp:SubStr(aRet[2],3,4) + SubStr(aRet[2],1,2)% ) 
		       AND ( A1_CGC <> %exp:cCnpjBB%  
		              OR A1_CGC <> %exp:cCnpjCX% ) 
		GROUP  BY E1_PREFIXO, 
		          E1_NUM,
		          E1_VALOR,
		          E1_CLIENTE, 
		          E1_LOJA, 
		          E1_NOMCLI,
		          E1_TIPO, 
		          E1_XIDFATU, 
		          ZC6_IDFATU, 
		          ZC6_COMPET, 
		          ZC6_QTDE, 
		          ZC6_VALOR, 
		          ZC6_VLRTOT, 
		          ZC6_LOCCON, 
		          ZC0_NOME, 
		          ZC6_IDCONT 
		 EndSql
		 
		(cTab)->(DbGoTop())
		if (cTab)->(!Eof())

			// GRAVA ITEM - ZCD
			cIdRep := GetSXENum("ZCC","ZCC_IDREP")
			ConfirmSX8()

			While (cTab)->(!Eof())

				RecLock("ZCD",.T.)
					ZCD->ZCD_FILIAL	:= xFilial('ZCD')
					ZCD->ZCD_IDREP 	:= cIdRep
					ZCD->ZCD_TIPO  	:= "FRM"
					ZCD->ZCD_PFXREP	:= (cTab)->E1_PREFIXO
					ZCD->ZCD_VENCTO	:= dDataBase
					ZCD->ZCD_EMISSA	:= dDataBase
					ZCD->ZCD_QTDE	:= (cTab)->QTDE
					ZCD->ZCD_VALOR	:= (cTab)->E1_VALOR//GetMv('CI_VLRUFRM')
					ZCD->ZCD_VALTOT	:= (cTab)->QTDE*GetMv('CI_VLRUFRM')
					ZCD->ZCD_CLIENT	:= (cTab)->E1_CLIENTE
					ZCD->ZCD_LOJA  	:= (cTab)->E1_LOJA
					ZCD->ZCD_TIPTIT	:= (cTab)->E1_TIPO
					ZCD->ZCD_UNREP  := (cTab)->ZC6_LOCCON
					ZCD->ZCD_STATUS	:= "1"
					ZCD->ZCD_RAZAOS	:= (cTab)->E1_NOMCLI
					ZCD->ZCD_CODCTR	:= (cTab)->ZC6_IDCONT
					ZCD->ZCD_IDLCTR	:= (cTab)->ZC6_LOCCON
					ZCD->ZCD_NUM	:= (cTab)->E1_NUM
				ZCD->(MsUnLock())

				(cTab)->(dBSkip())

			EndDo
			(cTab)->(DbCloseArea())

			cTab := GetNextAlias()
			BeginSql alias cTab
				SELECT ZCD.ZCD_IDREP, ZCD.ZCD_TIPO, ZCD.ZCD_PFXREP, ZCD.ZCD_VENCTO, ZCD.ZCD_EMISSA,
						ZCD.ZCD_TIPTIT, ZCD.ZCD_STATUS, SUM(ZCD.ZCD_VALTOT) TOTAL
				FROM %table:ZCD% ZCD
				WHERE ZCD.ZCD_FILIAL = %xFilial:ZCD%
				AND ZCD.ZCD_IDREP = %exp:cIdRep%
				AND ZCD.D_E_L_E_T_ = ' '
				GROUP BY ZCD.ZCD_IDREP, ZCD.ZCD_TIPO, ZCD.ZCD_PFXREP, ZCD.ZCD_EMISSA, ZCD.ZCD_VENCTO, ZCD.ZCD_TIPTIT, ZCD.ZCD_STATUS
				ORDER BY ZCD.ZCD_IDREP
			EndSql
//			aRet := GETLastQuery()[2]
			
			(cTab)->(DbGoTop())
			if (cTab)->(!Eof())

				RecLock("ZCC",.T.)
					ZCC->ZCC_FILIAL	:= xFilial('ZCC')
					ZCC->ZCC_COMPET	:= aRet[2]
					ZCC->ZCC_IDREP 	:= cIdRep
					ZCC->ZCC_TIPREP	:= "FRM"
					ZCC->ZCC_PFXREP	:= (cTab)->ZCD_PFXREP
					ZCC->ZCC_VENCTO	:= dDataBase
					ZCC->ZCC_EMISSA	:= dDataBase
					ZCC->ZCC_VALUNT	:= GetMv('CI_VLRUFRM')
					ZCC->ZCC_VALTIT	:= (cTab)->TOTAL
					ZCC->ZCC_FORNRE	:= SA2->A2_COD // FRM
					ZCC->ZCC_LOJA  	:= SA2->A2_LOJA
					ZCC->ZCC_TIPTIT	:= (cTab)->ZCD_TIPTIT
					ZCC->ZCC_STATUS	:= "1"
					ZCC->ZCC_PRODRE	:= GetMv('CI_PRODFRM')
				ZCC->(MsUnLock())

				MsgInfo("Repasse importado com sucesso.","ATENÇÃO")

			endif
			(cTab)->(DbCloseArea())
		else
			MsgInfo("Não foram encontrados dados para os parâmetros informados.","ATENÇÃO")
			(cTab)->(DbCloseArea())
		endif

	elseif SubStr(aRet[1],1,1) == "2"  // Autônomo pagar

		If Empty(aRet[2])
			MsgInfo("Informe uma Competência.", "ATENÇÃO")
			Return
		endif

		cTab := GetNextAlias()
		BeginSql alias cTab
			SELECT ZC5_CLIENT, ZC5_LOJA, ZC5_IDFATU, ZC6_COMPET, SUM(ZC6_QTDE) QTDE, ZC6_VALOR, ZC6_VLRTOT, ZC6_LOCCON,
			       ZC0_NOME, ZC6_IDCONT, ZC6_AUTUPG, ZC6_AUTPPG, ZC6_AUTVPG, ZC6_AUTURC, ZC6_AUTPRC, ZC6_AUTVRC, ZC6.R_E_C_N_O_ AS RECZC6,
				   SUM(ZC6_VLRTOT) TOTAL
			FROM %table:ZC6% ZC6
			JOIN %table:ZC5% ZC5 ON ZC5_FILIAL = ZC6_FILIAL AND ZC5_IDFATU = ZC6_IDFATU AND ZC5.D_E_L_E_T_ = ' '
			JOIN %table:ZC0% ZC0 ON ZC0_CODIGO = ZC6_IDCONT AND ZC0.D_E_L_E_T_ = ' '
			WHERE ZC6_FILIAL = %xFilial:ZC6%
			  AND ZC6_COMPET = %exp:aRet[2]%
			  AND ZC6_REPASS <> '1'
			  AND ZC6_GERZC5 = 'S'
			  AND (ZC6_AUTUPG <> ' ' AND ZC6_AUTURC = ' ')
			  AND ZC6_TIPFAT IN ('1','2')
			  AND ZC6_AUTFGE = '1'
			  AND ZC6.D_E_L_E_T_ = ' '
			GROUP BY ZC5_CLIENT, ZC5_LOJA, ZC5_IDFATU, ZC6_COMPET, ZC6_QTDE, ZC6_VALOR, ZC6_VLRTOT, ZC6_LOCCON, ZC0_NOME, ZC6_IDCONT, ZC6_AUTUPG,
			         ZC6_AUTURC, ZC6_AUTPPG, ZC6_AUTVPG, ZC6_AUTPRC, ZC6_AUTVRC, ZC6.R_E_C_N_O_
			ORDER BY ZC6_AUTUPG
		EndSql
//		aRet := GETLastQuery()[2]
//		ZC6_TIPFAT IN ('1','2') ==> Ter recebido pagamento(s) de um faturamento de CI , estagio direto ou centralizado
//		ZC6_AUTFGE = '1'        ==>Ter no fato gerador do pagamento a indicação de Repasse Autônomo flag = 1

		(cTab)->(DbGoTop())
		if (cTab)->(Eof())
			MsgInfo("Não foram encontrados dados para os parâmetros informados.","ATENÇÃO")
			(cTab)->(DbCloseArea())
			Return
		endif
		
		BEGIN TRANSACTION

			While (cTab)->(!Eof())
				
				if AllTrim(cAutuPg) <> AllTrim((cTab)->ZC6_AUTUPG)
					cIdRep := GetSXENum("ZCC","ZCC_IDREP")
					ConfirmSX8()
					cAutuPg := AllTrim((cTab)->ZC6_AUTUPG)
					aadd(aIdRep,{cIdRep})
				endif
				
				RecLock("ZCD",.T.)
					ZCD->ZCD_FILIAL	:= xFilial('ZCD')
					ZCD->ZCD_IDREP 	:= cIdRep
					ZCD->ZCD_TIPO  	:= "AUT"
					ZCD->ZCD_VENCTO	:= dDataBase
					ZCD->ZCD_EMISSA	:= dDataBase
					ZCD->ZCD_QTDE	:= (cTab)->QTDE
					ZCD->ZCD_VALOR	:= (cTab)->ZC6_VALOR
					ZCD->ZCD_VALTOT	:= (cTab)->TOTAL
					ZCD->ZCD_CLIENT	:= (cTab)->ZC5_CLIENT
					ZCD->ZCD_LOJA  	:= (cTab)->ZC5_LOJA
					ZCD->ZCD_UNREP  := (cTab)->ZC6_LOCCON
					ZCD->ZCD_STATUS	:= "1"
					ZCD->ZCD_RAZAOS	:= (cTab)->ZC0_NOME
					ZCD->ZCD_CODCTR	:= (cTab)->ZC6_IDCONT
					ZCD->ZCD_IDLCTR	:= (cTab)->ZC6_LOCCON
					ZCD->ZCD_AUTPPG	:= (cTab)->ZC6_AUTPPG
					ZCD->ZCD_AUTVPG	:= (cTab)->ZC6_AUTVPG
					ZCD->ZCD_AUTUPG	:= (cTab)->ZC6_AUTUPG
					//ZCD->ZCD_AUTPRC	:= (cTab)->ZC6_AUTPRC
					//ZCD->ZCD_AUTVRC	:= (cTab)->ZC6_AUTVRC
					//ZCD->ZCD_AUTURC	:= (cTab)->ZC6_AUTURC
					ZCD->ZCD_IDFATU := (cTab)->ZC5_IDFATU
				ZCD->(MsUnLock())
				
				ZC6->(DbGoTo((cTab)->RECZC6))
				RecLock("ZC6",.F.)
					ZC6->ZC6_REPASS := "1"
				ZC6->(MsUnLock())

				(cTab)->(dBSkip())

			EndDo
			(cTab)->(DbCloseArea())

			for nI = 1 to Len(aIdRep)

				cTab    := GetNextAlias()
				cCndQyr := "  AND ZCD.ZCD_IDREP = '" + AllTrim(aIdRep[nI][1]) + "'"
				cCndQyr := "%" + cCndQyr + "%"

				BeginSql alias cTab
					SELECT ZCD.ZCD_IDREP, ZCD.ZCD_TIPO, ZCD.ZCD_PFXREP, ZCD.ZCD_VENCTO, ZCD.ZCD_EMISSA,
							ZCD.ZCD_TIPTIT, ZCD.ZCD_STATUS, SUM(ZCD.ZCD_AUTVPG) TOTAL, ZCD_AUTUPG, ZCD_AUTURC
					FROM %table:ZCD% ZCD
					WHERE ZCD.ZCD_FILIAL = %xFilial:ZCD%
					%EXP:cCndQyr%
					AND ZCD.D_E_L_E_T_ = ' '
					GROUP BY ZCD.ZCD_IDREP, ZCD.ZCD_TIPO, ZCD.ZCD_PFXREP, ZCD.ZCD_EMISSA, ZCD.ZCD_VENCTO, ZCD.ZCD_TIPTIT, ZCD.ZCD_STATUS, ZCD_AUTUPG, ZCD_AUTURC
					ORDER BY ZCD.ZCD_IDREP
				EndSql
	//			aRet := GETLastQuery()[2]

				(cTab)->(DbGoTop())

				RecLock('ZCC',.T.)
					ZCC->ZCC_FILIAL	:= xFilial('ZCC')
					ZCC->ZCC_COMPET	:= aRet[2]
					ZCC->ZCC_IDREP 	:= aIdRep[nI][1]
					ZCC->ZCC_TIPREP	:= "AUT"
					ZCC->ZCC_REPAPR := "P"
					ZCC->ZCC_PFXREP	:= (cTab)->ZCD_PFXREP
					ZCC->ZCC_VENCTO	:= dDataBase
					ZCC->ZCC_EMISSA	:= dDataBase
					ZCC->ZCC_VALUNT	:= 0
					ZCC->ZCC_VALTIT	:= (cTab)->TOTAL
	//				ZCC->ZCC_FORNRE	:= SA2->A2_COD
	//				ZCC->ZCC_LOJA  	:= SA2->A2_LOJA
					ZCC->ZCC_TIPTIT	:= (cTab)->ZCD_TIPTIT
					ZCC->ZCC_STATUS	:= "1"
					ZCC->ZCC_PRODRE	:= ""
					ZCC->ZCC_AUTUPG := (cTab)->ZCD_AUTUPG
					//ZCC->ZCC_AUTURC := (cTab)->ZCD_AUTURC
				ZCC->(MsUnLock())
				(cTab)->(DbCloseArea())
			next
		
		END TRANSACTION
		
		MsgInfo("Repasse gerado com sucesso.","ATENÇÃO")

	elseif SubStr(aRet[1],1,1) == "3"  // Autônomo receber

		If Empty(aRet[2])
			MsgInfo("Informe uma Competência.", "ATENÇÃO")
			Return
		endif
			
		cTab := GetNextAlias()
		BeginSql alias cTab
			SELECT ZC5_CLIENT, ZC5_LOJA, ZC5_IDFATU, ZC6_COMPET, SUM(ZC6_QTDE) QTDE, ZC6_VALOR, ZC6_VLRTOT, ZC6_LOCCON,
			       ZC0_NOME, ZC6_IDCONT, ZC6_AUTUPG, ZC6_AUTPPG, ZC6_AUTVPG, ZC6_AUTURC, ZC6_AUTPRC, ZC6_AUTVRC, ZC6.R_E_C_N_O_ AS RECZC6,
				   SUM(ZC6_VLRTOT) TOTAL
			FROM %table:ZC6% ZC6
			JOIN %table:ZC5% ZC5 ON ZC5_FILIAL = ZC6_FILIAL AND ZC5_IDFATU = ZC6_IDFATU AND ZC5.D_E_L_E_T_ = ' '
			JOIN %table:ZC0% ZC0 ON ZC0_CODIGO = ZC6_IDCONT AND ZC0.D_E_L_E_T_ = ' '
			WHERE ZC6_FILIAL = %xFilial:ZC6%
			  AND ZC6_COMPET = %exp:aRet[2]%
			  AND ZC6_REPASS <> '1'
			  AND ZC6_GERZC5 = 'S'
			  AND (ZC6_AUTUPG = ' ' AND ZC6_AUTURC <> ' ')
			  AND ZC6_TIPFAT IN ('1','2')
			  AND ZC6_AUTFGE = '1'
			  AND ZC6.D_E_L_E_T_ = ' '
			GROUP BY ZC5_CLIENT, ZC5_LOJA, ZC5_IDFATU, ZC6_COMPET, ZC6_QTDE, ZC6_VALOR, ZC6_VLRTOT, ZC6_LOCCON, ZC0_NOME, ZC6_IDCONT, ZC6_AUTUPG,
			         ZC6_AUTURC, ZC6_AUTPPG, ZC6_AUTVPG, ZC6_AUTPRC, ZC6_AUTVRC, ZC6.R_E_C_N_O_
			ORDER BY ZC6_AUTUPG
		EndSql
//		aRet := GETLastQuery()[2]
//		ZC6_TIPFAT IN ('1','2') ==> Ter recebido pagamento(s) de um faturamento de CI , estagio direto ou centralizado
//		ZC6_AUTFGE = '1'        ==>Ter no fato gerador do pagamento a indicação de Repasse Autônomo flag = 1

		(cTab)->(DbGoTop())
		if (cTab)->(Eof())
			MsgInfo("Não foram encontrados dados para os parâmetros informados.","ATENÇÃO")
			(cTab)->(DbCloseArea())
			Return
		endif
		
		BEGIN TRANSACTION

			While (cTab)->(!Eof())
				
				if AllTrim(cAutuRc) <> AllTrim((cTab)->ZC6_AUTURC)
					cIdRep := GetSXENum("ZCC","ZCC_IDREP")
					ConfirmSX8()
					cAutuRc := AllTrim((cTab)->ZC6_AUTURC)
					aadd(aIdRep,{cIdRep})
				endif
				
				RecLock("ZCD",.T.)
					ZCD->ZCD_FILIAL	:= xFilial('ZCD')
					ZCD->ZCD_IDREP 	:= cIdRep
					ZCD->ZCD_TIPO  	:= "AUT"
					ZCD->ZCD_VENCTO	:= dDataBase
					ZCD->ZCD_EMISSA	:= dDataBase
					ZCD->ZCD_QTDE	:= (cTab)->QTDE
					ZCD->ZCD_VALOR	:= (cTab)->ZC6_VALOR
					ZCD->ZCD_VALTOT	:= (cTab)->TOTAL
					ZCD->ZCD_CLIENT	:= (cTab)->ZC5_CLIENT
					ZCD->ZCD_LOJA  	:= (cTab)->ZC5_LOJA
					ZCD->ZCD_UNREP  := (cTab)->ZC6_LOCCON
					ZCD->ZCD_STATUS	:= "1"
					ZCD->ZCD_RAZAOS	:= (cTab)->ZC0_NOME
					ZCD->ZCD_CODCTR	:= (cTab)->ZC6_IDCONT
					ZCD->ZCD_IDLCTR	:= (cTab)->ZC6_LOCCON
					//ZCD->ZCD_AUTPPG	:= (cTab)->ZC6_AUTPPG
					//ZCD->ZCD_AUTVPG	:= (cTab)->ZC6_AUTVPG
					//ZCD->ZCD_AUTUPG	:= (cTab)->ZC6_AUTUPG
					ZCD->ZCD_AUTPRC	:= (cTab)->ZC6_AUTPRC
					ZCD->ZCD_AUTVRC	:= (cTab)->ZC6_AUTVRC
					ZCD->ZCD_AUTURC	:= (cTab)->ZC6_AUTURC
					ZCD->ZCD_IDFATU := (cTab)->ZC5_IDFATU
				ZCD->(MsUnLock())
				
				ZC6->(DbGoTo((cTab)->RECZC6))
				RecLock("ZC6",.F.)
					ZC6->ZC6_REPASS := "1"
				ZC6->(MsUnLock())

				(cTab)->(dBSkip())

			EndDo
			(cTab)->(DbCloseArea())

			for nI = 1 to Len(aIdRep)

				cTab    := GetNextAlias()
				cCndQyr := "  AND ZCD.ZCD_IDREP = '" + AllTrim(aIdRep[nI][1]) + "'"
				cCndQyr := "%" + cCndQyr + "%"

				BeginSql alias cTab
					SELECT ZCD.ZCD_IDREP, ZCD.ZCD_TIPO, ZCD.ZCD_PFXREP, ZCD.ZCD_VENCTO, ZCD.ZCD_EMISSA,
							ZCD.ZCD_TIPTIT, ZCD.ZCD_STATUS, SUM(ZCD.ZCD_AUTVRC) TOTAL, ZCD_AUTUPG, ZCD_AUTURC
					FROM %table:ZCD% ZCD
					WHERE ZCD.ZCD_FILIAL = %xFilial:ZCD%
					%EXP:cCndQyr%
					AND ZCD.D_E_L_E_T_ = ' '
					GROUP BY ZCD.ZCD_IDREP, ZCD.ZCD_TIPO, ZCD.ZCD_PFXREP, ZCD.ZCD_EMISSA, ZCD.ZCD_VENCTO, ZCD.ZCD_TIPTIT, ZCD.ZCD_STATUS, ZCD_AUTUPG, ZCD_AUTURC
					ORDER BY ZCD.ZCD_IDREP
				EndSql
	//			aRet := GETLastQuery()[2]

				(cTab)->(DbGoTop())

				RecLock('ZCC',.T.)
					ZCC->ZCC_FILIAL	:= xFilial('ZCC')
					ZCC->ZCC_COMPET	:= aRet[2]
					ZCC->ZCC_IDREP 	:= aIdRep[nI][1]
					ZCC->ZCC_TIPREP	:= "AUT"
					ZCC->ZCC_REPAPR := "R"
					ZCC->ZCC_PFXREP	:= (cTab)->ZCD_PFXREP
					ZCC->ZCC_VENCTO	:= dDataBase
					ZCC->ZCC_EMISSA	:= dDataBase
					ZCC->ZCC_VALUNT	:= 0
					ZCC->ZCC_VALTIT	:= (cTab)->TOTAL
					ZCC->ZCC_TIPTIT	:= (cTab)->ZCD_TIPTIT
					ZCC->ZCC_STATUS	:= "1"
					ZCC->ZCC_PRODRE	:= ""
					ZCC->ZCC_AUTURC := (cTab)->ZCD_AUTURC
				ZCC->(MsUnLock())

				//Gera numero título a receber
				cNumTit := GetSXENum("SE1","E1_NUM")
				ConfirmSX8()
				
				//Busca cliente/loja
				cCNPJAUT := GetAdvFVal("ZCN","ZCN_CNPJ" ,XFILIAL("ZCN")+(cTab)->ZCD_AUTURC,1) 
				aSA1     := GetAdvFVal("SA1",{"A1_COD","A1_LOJA"} ,XFILIAL("SA1")+cCNPJAUT,3) 

				//Gera titulo provisório a receber
				aTitRec := {{"E1_PREFIXO" ,"AUT",Nil},;
				{"E1_NUM" ,cNumTit,Nil},;
				{"E1_PARCELA" ,"",Nil},;
				{"E1_TIPO" ,"PR" ,Nil},;
				{"E1_FILIAL" ,xFilial("SE1") ,Nil},;
				{"E1_NATUREZ" ,ALLTRIM(GetMv("CI_NATREPA",.F.,"99999999")),Nil},;
				{"E1_CLIENTE" ,aSA1[1],Nil},;
				{"E1_LOJA" ,aSA1[2],Nil},;
				{"E1_EMISSAO" ,date(),Nil},;
				{"E1_VENCTO" ,lastDay(date()),Nil},;
				{"E1_XCOMPET" ,aRet[2],Nil },;
				{"E1_VALOR" ,(cTab)->TOTAL,Nil },;
				{"E1_XIDREP" ,aIdRep[nI][1],Nil }}

				MSExecAuto({|x, y| FINA040(x, y)}, aTitRec, 3) // 3 – Inclusao, 4 – Alteração, 5 – Exclusão
				
				If lMsErroAuto
					_cMsg := "Falha na geração do(s)  titulo(s) a receber"
					MOSTRAERRO()
					DisarmTransaction()
				EndIf

				(cTab)->(DbCloseArea())

			next
		
		END TRANSACTION
		
		MsgInfo(_cMsg,"ATENÇÃO")
		
	Else

		MsgInfo("Opção não disponível.", "ATENÇÃO")

	EndIf

EndIf

Return


/*/{Protheus.doc} CCK05EST
Estorna competência
@author
@since 21/07/2020
@version 12.1.25
@type user function
/*/
User Function CCK05EST()

Local cIdRep   := ""
Local cRepaPR  := ""
Local lEstorno := .F.
Local aTitRec  := {}
Local cTitProv := ""

Private cIdRepNEst := ""
Private aRet   := {}
Private aPergs := {}
Private lMsErroAuto := .F.

aAdd(aPergs ,{2,"Tipo Repasse ?","1 - FRM",{"1 - FRM","2 - ICN Pagar","3 - ICN Receber Prov.","4 - Empresas"},60,"",.F.})
aAdd(aPergs ,{1,"Competência (MMAAAA) ?",Space(6),"@!",'','','.T.',40,.F.})

If ParamBox(aPergs ,"Parametros",aRet)

	If SubStr(aRet[1],1,1) == "1"  // FRM

		If !Empty(aRet[2])

			ZCC->(dBSetOrder(2))
			If ZCC->(dBSeek(xFilial('ZCC')+aRet[2]+"FRM"))

				If ZCC->ZCC_STATUS <> '1'

					MsgInfo("Competência informada não se encontra mais em Aberto !!", "ATENÇÃO!!")

				Else

					If MSGYESNO("Confirma Estorno dessa Competência?")

						// Exclui o registros da tabela ZCC e ZCD

						cIdRep	:= ZCC->ZCC_IDREP

						If RecLock("ZCC",.F.)
							ZCC->(DbDelete())
							ZCC->(MsUnLock())
						endif

						If ZCD->(dBSeek(xFilial('ZCD')+cIdRep))

							While xFilial('ZCD')+cIdRep == ZCD->ZCD_FILIAL+ZCD->ZCD_IDREP .And. ZCD->(!Eof())

								If RecLock("ZCD",.F.)
									ZCD->(DbDelete())
									ZCD->(MsUnLock())
								endif

								ZCD->(dBSkip())

							EndDo

						EndIf

					endif

				EndIf

			else

				MsgInfo("Competência informada Inexiste!!", "ATENÇÃO!!")

			EndIf

		Else

			MsgInfo("Competência informada Inexiste!!", "ATENÇÃO!!")

		EndIf

	elseIf (SubStr(aRet[1],1,1) == "2" .or. SubStr(aRet[1],1,1) == "3")// Autônomo

		If MsgYesNo("Confirma estorno da Competência " + aRet[2] + "?")

			cRepaPR := IIF(SubStr(aRet[1],1,1) == "2","P","R") //Indica se é um estorno de repasse a pagar ou receber

			If !Empty(aRet[2])

				ZCC->(dBSetOrder(2))
				If ZCC->(dBSeek(xFilial('ZCC')+AvKey(aRet[2],"ZCC_COMPET")+"AUT"+cRepaPR))

					While !ZCC->(EOF()) .and. ZCC->ZCC_FILIAL == xFilial('ZCC');
					                    .and. ZCC->ZCC_COMPET == aRet[2];
										.and. ZCC->ZCC_TIPREP  == "AUT";
										.and. ZCC->ZCC_REPAPR  == cRepaPR

						if EstornoOK(cRepaPR)

							BEGIN TRANSACTION

							// Exclui o registro da tabela ZCC e ZCD
							If ZCD->(dBSeek(xFilial('ZCD')+ZCC->ZCC_IDREP))

								While xFilial('ZCD')+ZCC->ZCC_IDREP == ZCD->ZCD_FILIAL+ZCD->ZCD_IDREP .And. ZCD->(!Eof())
									
									ZC6->(DbSetOrder(02))
									if ZC6->(DbSeek(ZCD->ZCD_IDFATU))
										If RecLock("ZC6",.F.)
											ZC6->ZC6_REPASS := '2'
											ZC6->(MsUnLock())
										endif
									endif

									If RecLock("ZCD",.F.)
										ZCD->(DbDelete())
										ZCD->(MsUnLock())
									endif

									ZCD->(dBSkip())

								EndDo

							EndIf

							If RecLock("ZCC",.F.)
								ZCC->(DbDelete())
								ZCC->(MsUnLock())
							endif

							if cRepaPR=="R" //Se for repasse a receber exclui também o título provisório

								SE1->(DbOrderNickName("IDREPASS"))
								if SE1->(DbSeek(xFilial("SE1")+ZCC->ZCC_IDREP))

									aTitRec := {{"E1_PREFIXO" ,SE1->E1_PREFIXO,Nil},;
									{"E1_NUM" ,SE1->E1_NUM,Nil},;
									{"E1_PARCELA" ,SE1->E1_PARCELA,Nil},;
									{"E1_TIPO" ,SE1->E1_TIPO,Nil},;
									{"E1_FILIAL" ,SE1->E1_FILIAL ,Nil},;
									{"E1_NATUREZ" ,SE1->E1_NATUREZ,Nil},;
									{"E1_CLIENTE" ,SE1->E1_CLIENTE,Nil},;
									{"E1_LOJA" ,SE1->E1_LOJA,Nil},;
									{"E1_EMISSAO" ,SE1->E1_EMISSAO,Nil},;
									{"E1_VENCTO" ,SE1->E1_VENCTO,Nil},;
									{"E1_VALOR" ,SE1->E1_VALOR,Nil },;
									{"E1_XIDREP" ,SE1->E1_XIDREP,Nil }}

									MSExecAuto({|x, y| FINA040(x, y)}, aTitRec, 5) // 3 – Inclusao, 4 – Alteração, 5 – Exclusão
									
									If lMsErroAuto
										cTitProv += "/TIT: "+ALLTRIM(SE1->E1_NUM)+" IDR: "+ALLTRIM(SE1->E1_XIDREP)
										//MOSTRAERRO()
										DisarmTransaction()
									EndIf
								
								endif

							endif

							lEstorno := .T.

							END TRANSACTION

						EndIf

						ZCC->(DBSKIP())

					End

					if lEstorno .and. Empty(cIdRepNEst)
						MsgInfo("Estorno da Competência: " + aRet[2] + " efetuado com sucesso.", "ATENÇÃO!!")
					elseif lEstorno .and. !Empty(cIdRepNEst)
						MsgInfo("Competência estornada, porém alguns repasses não puderam ser estornados pois já foram efetivados: " + alltrim(cIdRepNEst), "ATENÇÃO!!")
					elseif lEstorno==.F. .and. !Empty(cIdRepNEst)
						MsgInfo("Competência não pode ser estornada pois todos repasses já foram efetivados ", "ATENÇÃO!!")
					elseif lEstorno==.F. .and. Empty(cIdRepNEst)
						MsgInfo("Não foram encontrados movimentos de repasse para estornar ", "ATENÇÃO!!")
					endif

					if !Empty(cTitProv)
						MsgInfo("Falha na exclusão do(s) seguintes(s) titulo(s) a receber provisório: " + alltrim(cIdRepNEst), "ATENÇÃO!!")	
					endif
				else

					MsgInfo("Competência informada Inexiste!!", "ATENÇÃO!!")

				EndIf

			Else

				MsgInfo("Necessário informar competência!!", "ATENÇÃO!!")

			EndIf

		EndIf

	Else

		MsgInfo("Opção não disponível.", "ATENÇÃO")

	EndIf

EndIf

Return

/*/{Protheus.doc} CCK05VIS
Visualizar Repasses
@author
@since 21/07/2020
@version 12.1.25
@type user function
/*/
User Function CCK05VIS()

Local cUnidade  := ""
Local oScroll 	:= NIL
Local nTop 		:= 5
Local n 		:= 0
Local cGet 		:= ""
Local cPict 	:= ""
Local cVar 		:= ""
Local oLbx1 	:= NIL
Local aTitulo 	:= {}
Local nOpcA    	:= 0
Local nTotApr   := 0
Local nValTotal := 0
Local aButtons  := {}

Private bGet 	:= NIL
Private oGet 	:= NIL
Private oDlg 	:= NIL
Private cTitulo := "Repasses"
Private aSay 	:= {}

DbSelectarea("ZCN")
ZCN->(DbSetOrder(01))

If ZCD->(dBSeek(xFilial('ZCD')+ZCC->ZCC_IDREP))

	While !ZCD->(Eof()) .And. ZCD->ZCD_FILIAL+ZCD->ZCD_IDREP = ZCC->ZCC_FILIAL+ZCC->ZCC_IDREP

		SA1->(dBSetOrder(1))
		SA1->(dBSeek(xFilial("SA1")+ZCD->ZCD_CLIENT+ZCD->ZCD_LOJA))
		
		nTotApr += ZCD->ZCD_QTDE	
		
		aAdd(aTitulo,{	Alltrim(STR(ZCD->ZCD_QTDE)),;
						Transform(ZCD->ZCD_VALOR	,"@E 99,999,999,999.99"),;
						Alltrim(Transform(ZCD->ZCD_QTDE * GetMv('CI_VLRUFRM'),"@E 99,999,999,999.99")),;
						ZCD->ZCD_CLIENT,;
						ZCD->ZCD_LOJA,;
						SA1->A1_NREDUZ,;
						ZCD->ZCD_TIPTIT,;
						ZCD->ZCD_UNREP,;
						DTOC(ZCD->ZCD_VENCTO),;
						DTOC(ZCD->ZCD_EMISSA),;
						ZCD->ZCD_RAZAOS,;
						ZCD->ZCD_CODCTR,;
						ZCD->ZCD_IDLCTR,;
						ZCD->ZCD_NUM })

		ZCD->(dBSkip())

	EndDo

Else

	aAdd(aTitulo,{	"",;
					"",;
					"",;
					"",;
					"",;
					"",;
					"",;
					"",;
					"",;
					"",;
					"",;
					"",;
					""})

EndIf

//nTotApr   := U_RetTotApr()
	
nValTotal := nTotApr * GetMv('CI_VLRUFRM')

aSize := MsAdvSize(.F.)
DEFINE MSDIALOG oDlg TITLE cTitulo FROM aSize[7],0 To aSize[6],aSize[5] OF oDlg PIXEL

	Aadd( aButtons, {"HISTORIC", {|| U_CRELK05A()}, "Histórico...", "Rel. Analitico" , {|| .T.}} )  

	@ 033,002 TO aSize[4],0192     LABEL "Repasse - Sintético" OF oDlg PIXEL
	@ 033,195 TO aSize[4],aSize[6] LABEL "Repasse - Analítico" OF oDlg PIXEL

	@ 042,006 SCROLLBOX oScroll HORIZONTAL VERTICAL SIZE aSize[4]-46,182 OF oDlg BORDER
	oDlg:lMaximized := .T.  // Maximiza a janela
	oDlg:lCentered 	:= .T.  // Centraliza a tela

	If !ZCC->(Eof())

		aAdd(aSay,{"Competencia ", "C", 06, 0, "ZCC->ZCC_COMPET", "@!"        })
		aAdd(aSay,{"ID Repasse  ", "C", 09, 0, "ZCC->ZCC_IDREP" , "@!"        })
		aAdd(aSay,{"Tipo Repasse", "C", 03, 0, "ZCC->ZCC_TIPREP", "@!"        })
		aAdd(aSay,{"Prefixo Tit.", "C", 03, 0, "ZCC->ZCC_PFXREP", "@!"        })
		aAdd(aSay,{"Vencto Repas", "D", 08, 0, "ZCC->ZCC_VENCTO", "99/99/9999"})
		aAdd(aSay,{"Emissao Rep.", "D", 08, 0, "ZCC->ZCC_EMISSA", "99/99/9999"})
		if ZCC->ZCC_TIPREP <> "AUT"
			aAdd(aSay,{"Val. Unit.  ", "N", 16, 2, "ZCC->ZCC_VALUNT", "@E 99,999,999,999.99"})
		endif
		aAdd(aSay,{"Total Apr.  ", "N", 16, 4, "nTotApr","@!"})
		aAdd(aSay,{"Val. Total"  , "N", 04, 2, "nValTotal","@E 99,999,999,999.99"})
		aAdd(aSay,{"Fornecedor  ", "C", 06, 0, "ZCC->ZCC_FORNRE", "@!"                     })
		aAdd(aSay,{"Loja        ", "C", 02, 0, "ZCC->ZCC_LOJA"  , "@!"                     })
		aAdd(aSay,{"Tipo Titulo ", "C", 03, 0, "ZCC->ZCC_TIPTIT", "@!"                     })
		aAdd(aSay,{"Produto     ", "C", 15, 0, "ZCC->ZCC_PRODRE", "@!"                     })
		aAdd(aSay,{"Documento   ", "C", 09, 0, "ZCC->ZCC_NUMDOC", "@!"                     })
		aAdd(aSay,{"Serie       ", "C", 03, 0, "ZCC->ZCC_SERIE" , "@!"                     })
		aAdd(aSay,{"ID Fluig    "," C", 08, 0, "ZCC->ZCC_NUMFLG", "@!"                     })
		if ZCC->ZCC_TIPREP == "AUT"
			if !Empty(ZCC->ZCC_AUTUPG)
				cUnidade := ZCC->ZCC_AUTUPG
			else
				cUnidade := ZCC->ZCC_AUTURC
			endif
			if ZCN->(DbSeek(xFilial("ZCN")+cUnidade))
				cUnidade := AllTrim(cUnidade) + " - " + AllTrim(ZCN->ZCN_DLOCAL)
			else
				cUnidade := AllTrim(cUnidade) + " - UNIDADE NÃO CADASTRADA NA TABELA ZCN"
			endif
			aAdd(aSay,{"CIEE Pagar  ", "C", 68, 0, "cUnidade", "@!"})
		endif

		For n:=1 TO Len(aSay)
			bGet  := &("{|| '"+aSay[n,1]+"'}")
			cVar  := aSay[n,5]
			cGet  := "{|u| iif(PCount()>0,"+cVar+":=u,"+cVar+")}"
			cPict := aSay[n,6]
			TSay():New(nTop,5,bGet,oScroll,,,.F.,.F.,.F.,.T.,,,GetTextWidth(0,Trim(aSay[n,1])),15,.F.,.F.,.F.,.F.,.F.)
			oGet:=TGet():New(nTop-2,40,&cGet,oScroll,,7,cPict,,,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,(cVar),,,,.T.)
			nTop+=11
		Next n

		// List box Analíticos

		@ 046,199 LISTBOX oLbx1 FIELDS HEADER ;
			"Qtd. Apr.", "Valor Faturamento", "Valor Repasse", ;
			"Cliente", "Tipo Tit.","Num. Tit.","Vencto.", "Emissão", "Razão Social", "Contrato", "ID Local Contrato" ;
			SIZE aSize[5]-350,aSize[4]-50 OF oDlg PIXEL 

		oLbx1:SetArray( aTitulo )
		oLbx1:bLine := {|| {	aTitulo[oLbx1:nAt,01],;
								aTitulo[oLbx1:nAt,02],;
								aTitulo[oLbx1:nAt,03],;
								aTitulo[oLbx1:nAt,04],;
								aTitulo[oLbx1:nAt,07],;
								aTitulo[oLbx1:nAt,14],;
								aTitulo[oLbx1:nAt,09],;
								aTitulo[oLbx1:nAt,10],;
								aTitulo[oLbx1:nAt,11],;
								aTitulo[oLbx1:nAt,12],;
								aTitulo[oLbx1:nAt,13]}}

	EndIf

ACTIVATE MSDIALOG oDlg CENTER ON INIT EnchoiceBar(oDlg,{||nOpcA:=1,oDlg:End()},{||oDlg:End()},,@aButtons)

Return

/*/{Protheus.doc} CCK05FLG
Solicitação fluig
@author
@since 22/07/2020
@version undefined
@type user function
/*/
User function CCK05FLG()

Processa({||CCK05FLGA(),"Processando..."})

Return

/*/{Protheus.doc} CCK05FLGA
Rotina de integração com Fluig
@author
@since 22/07/2020
@version undefined
@type function
/*/
Static function CCK05FLGA()

local oFlg			:= CINTFLG():New(.T.)
local aCardData		:= {}

local cEmiss		:= ""
local cVencto		:= ""
local cRet			:= ""
Local cQuery		:= ""

Local cData			:= ""

Local cSubTot		:= 0

Local cTotGer		:= 0
Local cMenStat		:= ""

LOCAL oScroll 	:= NIL

Local oOk      	:= LoadBitmap( GetResources(), "LBOK" )
Local oNo      	:= LoadBitmap( GetResources(), "LBNO" )
LOCAL nTop 		:= 5
LOCAL n 		:= 0
LOCAL cGet 		:= ""
LOCAL cPict 	:= ""
LOCAL cVar 		:= ""
Local aAdvSize  := {}

Local oLbx1 	:= NIL
Local aTitulo 	:= {}
Local aTitulo1	:= {}
Local lMark    	:= .F.
Local nOpcA    	:= 0
Local cRegApr	:= TRIM(SuperGetMv("CI_PRENOT",.F.,"PRENOT"))

PRIVATE bGet 	:= NIL
PRIVATE oGet 	:= NIL
PRIVATE oDlg 	:= NIL
PRIVATE cTitulo := "REPASSE"
PRIVATE aSay 	:= {}
PRIVATE cGetNUM := Space(06)
Private aRet   := {}
Private aPergs := {}

//if Empty(ZCC->ZCC_NUMDOC) .OR. Empty(ZCC->ZCC_SERIE)
//	MsgAlert("O registro não possui documento e série informados, não será possível realizar o envio da aprovação","ATENÇÃO")
//	Return
//endif

aAdd(aPergs ,{2,"Tipo Repasse ?","1 - FRM",{"1 - FRM","2 - Autônomo","3 - Empresas"},60,"",.F.})
aAdd(aPergs ,{1,"Competência (MMAAAA) ?",Space(6),"@!",'','','.T.',40,.F.})

If ParamBox(aPergs ,"Parametros",aRet)

	If SubStr(aRet[1],1,1) == "1"  // FRM

		ProcRegua(100)

		cGetNUM	:= ZCC->ZCC_IDREP

		cQuery	:= "SELECT * FROM "+RetSqlName("ZCC")+" ZCC "
		cQuery	+= "WHERE ZCC_FILIAL= '"+xFilial('ZCC')+"' AND ZCC_COMPET= '"+MV_PAR02+"' AND ZCC_STATUS='1' AND ZCC.D_E_L_E_T_=' ' "
		cQuery	+= "ORDER BY ZCC_COMPET, ZCC_IDREP "

		MemoWrite("c:\Temp\testSave3"+".sql",cQuery)

		If Select('SOLI') > 0
			dbSelectArea('SOLI')
			dbCloseArea()
		EndIf

		dbUseArea( .T., 'TOPCONN', TCGENQRY(,,cQuery), "SOLI" , .F., .T.)

		If !SOLI->(Eof())

			While !SOLI->(Eof())

				SA2->(dBSetOrder(1))
				SA2->(dBSeek(xFilial("SA2")+ZCC->ZCC_FORNRE+ZCC->ZCC_LOJA))

				aAdd(aTitulo,{	lMark,;
					SOLI->ZCC_COMPET,;
					SOLI->ZCC_IDREP,;
					SOLI->ZCC_TIPREP,;
					SOLI->ZCC_PFXREP,;
					SOLI->ZCC_VENCTO,;
					SOLI->ZCC_EMISSA,;
					Transform(SOLI->ZCC_VALTIT	,"@E 99,999,999,999.99"),;
					SOLI->ZCC_FORNRE,;
					SOLI->ZCC_LOJA,;
					SA2->A2_NREDUZ,;
					SOLI->ZCC_TIPTIT})

				SOLI->(dBSkip())

			EndDo

		Else

			aAdd(aTitulo,{	lMark,;
				"",;
				"",;
				"",;
				"",;
				"",;
				"",;
				"",;
				"",;
				"",;
				"",;
				""})

		EndIf

		aSize := MsAdvSize(.F.)
		DEFINE MSDIALOG oDlg TITLE cTitulo FROM aSize[7],0 To aSize[6],aSize[5]	OF oDlg PIXEL
		
		@ 033,002 TO aSize[4],0192 LABEL "Repasse - Sintético"  		OF oDlg PIXEL // 219
		@ 033,195 TO aSize[4],aSize[6] LABEL "Repasse - Analítico"   	OF oDlg PIXEL // 348

		//scroll box Sintético

		cQuery	:= "SELECT ZCC_COMPET, ZCC_IDREP, ZCC_TIPREP, ZCD_PFXREP, ZCD_VENCTO, ZCD_EMISSA, "
		cQuery	+= "ZCD_VALTOT, ZCD_CLIENT, ZCD_LOJA, ZCD_TIPTIT "
		cQuery	+= "FROM "+RetSqlName("ZCC")+" ZCC "
		cQuery	+= "JOIN "+RetSqlName("ZCD")+" ZCD ON ZCC_FILIAL = ZCD_FILIAL AND "
		cQuery	+= "ZCC_IDREP = ZCD_IDREP AND ZCD.D_E_L_E_T_=' '  "
		cQuery	+= "WHERE ZCC_FILIAL = '"+xFilial("ZCC")+"' AND ZCC_COMPET = '"+MV_PAR02+"' AND ZCC.D_E_L_E_T_=' ' "
		cQuery	+= "ORDER BY ZCC_COMPET, ZCC_IDREP "

		MemoWrite("c:\Temp\testSave4"+".sql",cQuery)

		If Select('SOLI1') > 0
			dbSelectArea('SOLI1')
			dbCloseArea()
		EndIf

		dbUseArea( .T., 'TOPCONN', TCGENQRY(,,cQuery), "SOLI1" , .F., .T.)

		If !SOLI1->(Eof())

			While !SOLI1->(Eof())

				SA1->(dBSetOrder(1))
				SA1->(dBSeek(xFilial("SA1")+SOLI1->ZCD_CLIENT+SOLI1->ZCD_LOJA))

				aAdd(aTitulo1,{	lMark,;
								SOLI1->ZCC_COMPET,;
								SOLI1->ZCC_IDREP,;
								SOLI1->ZCC_TIPREP,;
								SOLI1->ZCD_PFXREP,;
								SOLI1->ZCD_VENCTO,;
								SOLI1->ZCD_EMISSA,;
								Transform(SOLI1->ZCD_VALTOT,"@E 99,999,999,999.99"),;
								SOLI1->ZCD_CLIENT,;
								SOLI1->ZCD_LOJA,;
								SA1->A1_NREDUZ,;
								SOLI1->ZCD_TIPTIT})

					SOLI1->(dBSkip())

			EndDo

		EndIf

		@ 042,006 SCROLLBOX oScroll HORIZONTAL VERTICAL SIZE aSize[4]-46,182 OF oDlg BORDER
		oDlg:lMaximized := .T. //Maximiza a janela
		oDlg:lCentered 	:= .T. // Centraliza a tela

		If !ZCC->(Eof())

			aAdd(aSay,{"Competencia "	,"C",06,0,"ZCC->ZCC_COMPET" 	,"@!"})
			aAdd(aSay,{"ID Repasse  "  	,"C",09,0,"ZCC->ZCC_IDREP "  	,"@!"})
			aAdd(aSay,{"Tipo Repasse"   ,"C",03,0,"ZCC->ZCC_TIPREP"		,"@!"})
			aAdd(aSay,{"Prefixo Tit."  	,"C",03,0,"ZCC->ZCC_PFXREP"		,"@!"})
			aAdd(aSay,{"Vencto Repas"  	,"D",08,0,"ZCC->ZCC_VENCTO" 	,"99/99/9999"})
			aAdd(aSay,{"Emissao Rep."  	,"D",08,0,"ZCC->ZCC_EMISSA" 	,"99/99/9999"})
			aAdd(aSay,{"Val. Total  "  	,"N",16,2,"ZCC->ZCC_VALTIT" 	,"@E 9,999,999,999,999.99"})
			aAdd(aSay,{"Fornecedor  "	,"C",06,0,"ZCC->ZCC_FORNRE"  	,"@!"})
			aAdd(aSay,{"Loja        " 	,"C",02,0,"ZCC->ZCC_LOJA  " 	,"@!"})
			aAdd(aSay,{"Tipo Titulo "	,"C",03,0,"ZCC->ZCC_TIPTIT"  	,"@!"})
			aAdd(aSay,{"Produto     " 	,"C",15,0,"ZCC->ZCC_PRODRE" 	,"@!"})
			aAdd(aSay,{"Documento	"	,"C",09,0,"ZCC->ZCC_NUMDOC"		,"@!"})
			aAdd(aSay,{"Serie		"	,"C",03,0,"ZCC->ZCC_SERIE"		,"@!"})
			aAdd(aSay,{"ID Fluig	"	,"C",08,0,"ZCC->ZCC_NUMFLG" 	,"@!"})

			For n:=1 TO Len(aSay)
				bGet := &("{|| '"+aSay[n,1]+"'}")
				cVar := aSay[n,5]
				cGet  := "{|u| iif(PCount()>0,"+cVar+":=u,"+cVar+")}"
				cPict := aSay[n,6]
				TSay():New(nTop,5,bGet,oScroll,,,.F.,.F.,.F.,.T.,,,GetTextWidth(0,Trim(aSay[n,1])),15,.F.,.F.,.F.,.F.,.F.)
				oGet:=TGet():New(nTop-2,40,&cGet,oScroll,,7,cPict,,,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,(cVar),,,,.T.)
				nTop+=11
			Next n

			//list box

			@ 046,199 LISTBOX oLbx1 FIELDS HEADER ;
			" ","Competencia", "ID Repasse", "Tipo Repasse", ;
			"Prefixo Tit.", "Vencto Repas", "Emissao Rep.", "Val. Total", "Fornecedor", "Loja", "Des. Resum.", "Tipo Titulo" ;
			SIZE aSize[5]-350,aSize[4]-50 OF oDlg PIXEL 

			oLbx1:SetArray( aTitulo )
			oLbx1:bLine := {|| {Iif(aTitulo[oLbx1:nAt,1],oOk,oNo),;
									aTitulo[oLbx1:nAt,2],;
									aTitulo[oLbx1:nAt,3],;
									aTitulo[oLbx1:nAt,4],;
									aTitulo[oLbx1:nAt,5],;
									aTitulo[oLbx1:nAt,6],;
									aTitulo[oLbx1:nAt,7],;
									aTitulo[oLbx1:nAt,8],;
									aTitulo[oLbx1:nAt,9],;
									aTitulo[oLbx1:nAt,10],;
									aTitulo[oLbx1:nAt,11],;
									aTitulo[oLbx1:nAt,12]}}

		EndIf
		ACTIVATE MSDIALOG oDlg CENTER ON INIT EnchoiceBar(oDlg,{||nOpcA:=1,oDlg:End()},{||oDlg:End()})

		If nOpcA == 1

			IncProc("Realizando integração com Fluig...")

			If oFlg:setUserId(,,"Siga") == .F.
				MSGINFO("Usuário sem permissão para uso dessa rotina!!")

			Else

				oFlg:lSslInsecure := .T.
				ZAA->(dBSetOrder(1))
				If ZAA->(dBSeek(xFilial("ZAA")+oFlg:UserId))

					dbSelectArea("ZAH")

					ZAH->(dbSetOrder(2))

					If ZAH->(msSeek(xFilial("ZAH") + alltrim(ZAA->ZAA_MATSUP)))

						ZCC->(dBSetOrder(2))
						If !ZCC->(dBSeek(xFilial('ZCC')+MV_PAR02))

							MsgInfo("Competência informada INEXISTE !!", "ATENÇÃO!!")

						Else

							If ZCC->ZCC_STATUS<>'1'
								
							Do Case
							Case ZCC->ZCC_STATUS == '2'
									cMenStat:= "Em Aprovação"
							Case ZCC->ZCC_STATUS == '3'
									cMenStat:= "Reprovado"
							Case ZCC->ZCC_STATUS == '4'
									cMenStat:= "Aprovado"
							EndCase

							MsgInfo("Competência informada se encontra "+cMenStat+" !!", "ATENÇÃO!!")
							cRet	:= .F.

						Else

								// CABEC
								oFlg:setUserId(,,"Siga")
								oFlg:lSslInsecure := .T.

								//Monta string com anexos relacionados ao banco de conhecimento ==> Recno posicionado
								aAnexo := {}
								If oFlg:setAnexo("ZCC")
									aAdd(aCardData,{"hdDocs"		, oFlg:IdDocs 			})
									aAdd(aAnexo,{oFlg:IdDocs,"/ERP_MP/01/01 Shared/ZCC/"})
								Else
									U_uCONOUT("Erro: "+oFlg:Error)
								EndIf

								cData	:= 	Str(Year(date()),4)+'-'+;
											Str(Month(date()),2)+"-"+;
											Str(Day(date()),2)

								cEmiss	:= 	Str(Year(ZCC->ZCC_EMISSA),4)+'-'+;
											Str(Month(ZCC->ZCC_EMISSA),2)+"-"+;
											Str(Day(ZCC->ZCC_EMISSA),2)

								cVencto	:= 	Str(Year(ZCC->ZCC_VENCTO),4)+'-'+;
											Str(Month(ZCC->ZCC_VENCTO),2)+"-"+;
											Str(Day(ZCC->ZCC_VENCTO),2)

								SA2->(dBsetOrder(1))
								SA2->(MsSeek(xFilial("SA2")+ZCC->ZCC_FORNRE+ZCC->ZCC_LOJA))

								cQuery	:= "SELECT * "
								cQuery	+= "FROM "+RetSqlName("ZAI")+" ZAI "
								cQuery	+= "WHERE ZAI_FILIAL = '"+xFilial("ZAI")+"' AND ZAI_MAT = '"+oFlg:UserId+"' AND "
								cQuery	+= "ZAI_REGRA = '"+cRegApr+"' AND ZAI_MATSUP = '"+alltrim(ZAA->ZAA_MATSUP)+"' AND "
								cQuery	+= "ZAI.D_E_L_E_T_=' ' "
								cQuery	+= "ORDER BY ZAI_MAT, ZAI_REGRA, ZAI_MATSUP "

								MemoWrite("c:\Temp\ZAISave5"+".sql",cQuery)

								If Select('TRBZAI') > 0
									dbSelectArea('TRBZAI')
									dbCloseArea()
								EndIf

								dbUseArea( .T., 'TOPCONN', TCGENQRY(,,cQuery), "TRBZAI" , .F., .T.)

								TRBZAI->(dBGoTop())

								aAdd(aCardData,{"txtSolicitante"			, "CIEE DIGITAL"})		// oFlg:Nome
								aAdd(aCardData,{"txtNumeroFluig"			, ""})
								aAdd(aCardData,{"txtDataSolicitacao"		, DTOC(Date())}) 				// cData formato permitido 2019-01-01
								// novos campos para "WF_Pre_nota
								aAdd(aCardData,{"txtMatSolicitante"			, oFlg:UserId})
								aAdd(aCardData,{"txtRamal"					, "1111"})
								aAdd(aCardData,{"txtCodCR"					, oFlg:CodCR})
								aAdd(aCardData,{"txtDescricaoCR"			, oFlg:DesCR})
								aAdd(aCardData,{"txtCodGrpApr"				, "Pool:Group:H"+TRIM(TRBZAI->ZAI_GRUPO) })
								aAdd(aCardData,{"txtNumNota"				, alltrim(ZCC->ZCC_NUMDOC)})
								aAdd(aCardData,{"txtSerieNota"				, alltrim(ZCC->ZCC_SERIE)})

								// adicionados
								aAdd(aCardData,{"txtConta"					, GetAdvFVal("SZK","ZK_NUMCON",xFilial("SZK")+ZCC->ZCC_FORNRE,5)})
								aAdd(aCardData,{"txtCodProcesso"			, "0"})
								aAdd(aCardData,{"txtAgencia"				, GetAdvFVal("SZK","ZK_AGENCIA",xFilial("SZK")+ZCC->ZCC_FORNRE,5)})
								aAdd(aCardData,{"txtEmpresa"				, alltrim(ZAA->ZAA_EMP)})
								aAdd(aCardData,{"txtCrValid"				, "165"})
								aAdd(aCardData,{"txtEspEntrada"				, "-BPE   -CA    -CF    -CTA   -CTE   -CTEOS -CTF   -CTM   -CTR   -NF    -NF3E  -NFA   -NFCE  -NFCEE -NFCF  -NFCFG -NFDS  -NFE   -NFFA  -NFP   -NFPS  -NFS   -NFSC  -NFSE  -NFST  -NTSC  -NTST  -OCC   -RPS   -SPED"})
								aAdd(aCardData,{"txtRegraAprovacao"			, "PRENOT"})
								aAdd(aCardData,{"txtCgc"					, alltrim(ZAA->ZAA_CGC)})
								aAdd(aCardData,{"txtNomeBanco"				, GetAdvFVal("SZK","ZK_NOMBCO",xFilial("SZK")+ZCC->ZCC_FORNRE,5)}) 
								aAdd(aCardData,{"txtCgcDinamico"			,"61600839000155"})
								aAdd(aCardData,{"txtForneceConta"			, alltrim(ZCC->ZCC_FORNRE)})
								aAdd(aCardData,{"txtNumBanco"				, GetAdvFVal("SZK","ZK_BANCO",xFilial("SZK")+ZCC->ZCC_FORNRE,5)})
								aAdd(aCardData,{"txtDigitoConta"			, ""})
								aAdd(aCardData,{"txtDva"					, GetAdvFVal("SZK","ZK_DVAG",xFilial("SZK")+ZCC->ZCC_FORNRE,5)})
								aAdd(aCardData,{"txtTipo"					, "1"})
								aAdd(aCardData,{"txtTotalGr"				, alltrim("0,00")})
								aAdd(aCardData,{"txtFilial"					, alltrim(ZAA->ZAA_FIL)})
								aAdd(aCardData,{"txtPrincipal"				, "0"})
								aAdd(aCardData,{"txtMatSuperior2"			, "H"+TRIM(TRBZAI->ZAI_GRUPO) })
								aAdd(aCardData,{"txtContaCorrente"			, GetAdvFVal("SZK","ZK_NUMCON",xFilial("SZK")+ZCC->ZCC_FORNRE,5)})
								// adicionados

								aAdd(aCardData,{"txtDataEmissao"			, DTOC(ZCC->ZCC_EMISSA)}) 		// DTOC(ZCC->ZCC_EMISSA)
								aAdd(aCardData,{"txtDataVenc"				, DTOC(ZCC->ZCC_VENCTO)})		// DTOC(ZCC->ZCC_VENCTO)
								aAdd(aCardData,{"txtDataVencString"			, DTOC(ZCC->ZCC_VENCTO)})		// DTOC(ZCC->ZCC_VENCTO)
								aAdd(aCardData,{"txtDtVenc" 				, DTOS(ZCC->ZCC_VENCTO)})		// DTOS(ZCC->ZCC_VENCTO
								aAdd(aCardData,{"txtHisFin"					, "REPASSE FUNDAÇÃO ROBERTO MARINHO"})

								aAdd(aCardData,{"txtPesquisaCnpj"			, alltrim(SA2->A2_CGC)})
								//aAdd(aCardData,{"txtCodFilial"				, alltrim("")})
								aAdd(aCardData,{"txtPesquisaNome"			, alltrim("")})
								aAdd(aCardData,{"txtCodFornecedor"			, alltrim(ZCC->ZCC_FORNRE)})
								aAdd(aCardData,{"txtLojaFornecedor"			, alltrim(ZCC->ZCC_LOJA)})
								aAdd(aCardData,{"txtNomeFornecedor"			, alltrim(SA2->A2_NOME)})
								aAdd(aCardData,{"txtUFFornecedor"			, alltrim(SA2->A2_EST)})
								aAdd(aCardData,{"slcTipo"					, alltrim("CONTA CORRENTE")})

								aAdd(aCardData,{"txtEspecieDoc"				, alltrim("NFS")})
								aAdd(aCardData,{"txtCodFilial"				, alltrim(FwFilial())})
								aAdd(aCardData,{"txtNomeFilial"				, alltrim(FwFilName(FwCodEmp(),FwFilial()))})

								// ITEM


								SB1->(dBSetOrder(1))
								SB1->(MsSeek(xFilial("SB1")+ZCC->ZCC_PRODRE))

								nSeqItem:= 1
								cSeqItem:= CVALTOCHAR(nSeqItem)

								aAdd(aCardData,{"txtSeqItem___"+cSeqItem			, StrZero(nSeqItem,4) })
								aAdd(aCardData,{"txtCodProduto___"+cSeqItem			, alltrim(ZCC->ZCC_PRODRE) })
								aAdd(aCardData,{"txtDescProduto___"+cSeqItem		, alltrim(SB1->B1_DESC) })
								aAdd(aCardData,{"txtQuantideItem___"+cSeqItem		, alltrim("1,00")})
								aAdd(aCardData,{"txtValorUnitarioItem___"+cSeqItem	, ALLTRIM(TransForm(ZCC->ZCC_VALTIT,PESQPICT("ZCC","ZCC_VALTIT"))) })
								aAdd(aCardData,{"txtValorTotalItem___"+cSeqItem		, ALLTRIM(TransForm(ZCC->ZCC_VALTIT,PESQPICT("ZCC","ZCC_VALTIT"))) })
								aAdd(aCardData,{"txtDescontoItem___"+cSeqItem		, ALLTRIM(Transform(0,"@E 99,999,999,999.99"))})
								aAdd(aCardData,{"txtCodCRDesp___"+cSeqItem			, oFlg:CodCR})
								aAdd(aCardData,{"txtPedido___"+cSeqItem				, ""})
								aAdd(aCardData,{"txtPedidoItem___"+cSeqItem			, ""})
								//adicionado
								aAdd(aCardData,{"dsCRDesp___"+cSeqItem				, oFlg:CodCR })
								aAdd(aCardData,{"txtAprovUnico___"+cSeqItem			, "" })
								aAdd(aCardData,{"txtNumNota"						, alltrim(ZCC->ZCC_NUMDOC)})
								
								//TOTAIS

								cTotGer		:= cSubTot

								aAdd(aCardData,{"txtSubTotal"				, alltrim(Transform(ZCC->ZCC_VALTIT	,"@E 99,999,999,999.99"))})
								aAdd(aCardData,{"txtTotalDesconto"			, alltrim("0,00")})
								aAdd(aCardData,{"txtTotalGeral"				, alltrim(Transform(ZCC->ZCC_VALTIT	,"@E 99,999,999,999.99"))})

								//DISPLAY FIELDS

								aAdd(aCardData,{"txtMatSuperior"			, alltrim(ZAH->ZAH_MATSUP)})

								IF 	oFlg:startprocess("WF_Pre_nota",;	// ProcessId // WF_BolsaAuxilio
									"0",;						// NextTask
									{oFlg:UserId},;
									"Inicio da aprovação: ",;
									oFlg:UserId,;
									.T.,;
									aAnexo /*oFlg:attachments*/,;
									aCardData)

									cRet := oFlg:IdSol

									// atualizando Status da Legenda

									RecLock('ZCC',.F.)

									ZCC->ZCC_STATUS	:= "2"
									ZCC->ZCC_NUMFLG := cRet

									dbCommit()
									MsUnLock()

									ZCD->(dBGoTop())
									If ZCD->(dBSeek(xFilial("ZCD")+cGetNUM))

										While ZCD->ZCD_IDREP  = cGetNUM			.And.;
											ZCD->ZCD_FILIAL = xFilial("ZCD")	.And.;
											ZCD->(Eof())

											RecLock('ZCD',.F.)
											ZCD->ZCD_STATUS	:= "2"
											dbCommit()
											MsUnLock()

											ZCD->(dBSkip())

											EndDo

									EndIf

									MSGINFO("Integração realizada com sucesso!!" +CRLF+CRLF + "Solicitação Numero: " + CVALTOCHAR(oFlg:IdSol))

								Else

									cRet := "Erro"

									MSGALERT("Erro: "+oFlg:Error)

								EndIf

							EndIf

						endif

					endif

				EndIf
			EndIf
		EndIf
	elseIf SubStr(aRet[1],1,1) == "2"  // Autônomos
		
		cTab := GetNextAlias()
		BeginSql alias cTab
			SELECT *
			FROM %table:ZCC% ZCC
			WHERE ZCC.ZCC_FILIAL = %xFilial:ZCC%
			AND ZCC.ZCC_TIPREP = 'AUT'
			AND ZCC.ZCC_STATUS = '1'
			AND ZCC.D_E_L_E_T_ = ' '
			ORDER BY ZCC.ZCC_COMPET, ZCC.ZCC_IDREP
		EndSql
//		aRet := GETLastQuery()[2]
		
		(cTab)->(DbGoTop())
		if (cTab)->(Eof())
			MsgInfo("Não foram encontrados dados para os parâmetros informados.","ATENÇÃO")
		endif
		
		while (cTab)->(!Eof())
			
			SA1->(DbSetOrder(01))
			SA1->(DbSeek(xFilial("SA1")+ZCC->ZCC_FORNRE+ZCC->ZCC_LOJA))

			aAdd(aTitulo,{	lMark,;
				(cTab)->ZCC_COMPET,;
				(cTab)->ZCC_IDREP,;
				(cTab)->ZCC_TIPREP,;
				(cTab)->ZCC_PFXREP,;
				(cTab)->ZCC_VENCTO,;
				(cTab)->ZCC_EMISSA,;
				Transform((cTab)->ZCC_VALTIT,"@E 99,999,999,999.99"),;
				(cTab)->ZCC_FORNRE,;
				(cTab)->ZCC_LOJA,;
				SA1->A1_NREDUZ,;
				(cTab)->ZCC_TIPTIT})
			(cTab)->(DbSkip())
		enddo

        aAdvSize:= MsAdvSize()
        DEFINE MSDIALOG oDlg TITLE "Repasses" FROM aAdvSize[7],aAdvSize[1] TO aAdvSize[6],aAdvSize[5] OF oMainWnd PIXEL STYLE DS_SYSMODAL
        
        EnchoiceBar(oDlg,{|| lOk:=.T. , oDlg:End() },{|| oDlg:End()},,)
        
        @ 08,10 SAY "Selecione os repasses para enviar para aprovação." SIZE 200,008 PIXEL OF oDlg
        @ 20,10 LISTBOX oLbx;
        FIELDS HEADER " ", RetTitle("ZCC_COMPET"),RetTitle("ZCC_IDREP"),RetTitle("ZCC_TIPREP"),RetTitle("ZCC_PFXREP"),;
            RetTitle("ZCC_VENCTO"),RetTitle("ZCC_EMISSA"),RetTitle("ZCC_VALTIT"),RetTitle("RC1_VENREA"),RetTitle("ZCC_FORNRE"),;
            RetTitle("ZCC_LOJA"),RetTitle("A1_NREDUZ"),RetTitle("ZCC_TIPTIT");
            SIZE 350,085 OF oDlg PIXEL 
        
        oLbx:SetArray( aTitulo )
        oLbx:bLine := {|| {Iif(aTitulo[oLbx:nAt,1],oOk,oNo),;
                            aTitulo[oLbx:nAt,2],;
                            aTitulo[oLbx:nAt,3],;
                            aTitulo[oLbx:nAt,4],;
                            aTitulo[oLbx:nAt,5],;
                            aTitulo[oLbx:nAt,6],;
                            aTitulo[oLbx:nAt,7],;
                            aTitulo[oLbx:nAt,8],;
                            aTitulo[oLbx:nAt,9],;
                            aTitulo[oLbx:nAt,10],;
                            aTitulo[oLbx:nAt,11],;
                            aTitulo[oLbx:nAt,12]}}
        oLbx:Align:= CONTROL_ALIGN_ALLCLIENT
        ACTIVATE MSDIALOG oDlg CENTER

	endif
endif

Return


//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCADKR5
REPASSE FRM - RELAT”RIO RESUMO FRM
@author  	Djalma Mathias
@since     	28/01/2020
@version  	P.12.1.17
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------

User Function CCADKR5()
	Local CbCont,CbTxt	

	Local aAPREST	:= {}

	Local _nI		:= 0

	Local cEstado	:= Space(50)

	Local cTotEst1	:= 0
	Local cTotEst2	:= 0
	Local cCodEst	:= ""

	Local cTotCap	:= 0
	Local cTotEmp	:= 0
	Local cTotGer	:= 0
	Local cValApr	:= 8.27
	Local cMesExt	:= ""
	Local cContEmp	:= 0

	Private cPerg   := "CCADKR5"

	Private cDirDocs	:= MsDocPath()
	Private cArquivo	:= CriaTrab(,.F.)
	Private cTempPath	:= Alltrim(GetTempPath())
	Private cCmd		:= cDirDocs+"\"+cArquivo+".xls"
	Private cPlan		:= ""

	cbtxt    := SPACE(10)
	cbcont   := 0
	li       := 80
	m_pag    := 1
	
	ValidPerg(cPerg)
	pergunte(cPerg,.T.)

	If MV_PAR02 == 2
		MsgAlert('Visualização e geração de relatório via spool indisponível',FunName()+' - '+ProcName())
		Return .F.
	EndIf

	cQuery 	:= " SELECT ZC1_ESTLOC CODEST, SX5.X5_DESCRI ESTADO,ZC0.ZC0_TIPAPR TIPO, Count(*) AS TOTEST, Sum(ZCD.ZCD_QTDE)  AS QUANTEST "
	cQuery 	+= " FROM " + RetSqlName("ZCC") + " ZCC (NOLOCK) "
	cQuery 	+= " JOIN " + RetSqlName("ZCD") + " ZCD ON  ZCD.ZCD_IDREP=ZCC.ZCC_IDREP AND ZCD.D_E_L_E_T_=' ' "
	cQuery 	+= " JOIN " + RetSqlName("ZC1") + " ZC1 ON  ZC1.ZC1_CODIGO = ZCD.ZCD_CODCTR AND ZC1.ZC1_LOCCTR = ZCD.ZCD_IDLCTR AND ZC1.D_E_L_E_T_=' ' "
	cQuery 	+= " JOIN " + RetSqlName("ZC0") + " ZC0 ON  ZC0.ZC0_CODIGO=ZC1.ZC1_CODIGO AND ZC0.D_E_L_E_T_=' ' "
	cQuery 	+= " JOIN " + RetSqlName("SX5") + " SX5 ON  SX5.X5_TABELA='12' AND SX5.X5_CHAVE=ZC1_ESTLOC AND SX5.D_E_L_E_T_=' ' "
	cQuery 	+= " WHERE ZCC.ZCC_COMPET = '" + MV_PAR01 + "' "
	cQuery 	+= " AND ZCC.D_E_L_E_T_ = ' ' "
	cQuery 	+= " AND ZC0.ZC0_TIPCON = '2'"
	cQuery 	+= " GROUP BY  ZC1.ZC1_ESTLOC, SX5.X5_DESCRI, ZC0.ZC0_TIPAPR "
	MemoWrite("c:\Temp\TestSave6"+".sql",cQuery)

	If Select("TRAB")>0
		TRAB->(dbCloseArea())
	EndIf

	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'TRAB', .F., .T.)

	If TRAB->(Eof().And.Bof())
		MsgAlert("Não há registros a serem processados!","Atenção!")
		TRAB->(dbCloseArea())
		Return
	EndIf

	// Cria cabecalho html da planilha
	If mv_par02==1
		CabPlan()
	EndIf

	cMesExt := Substr(MesExtenso(CtOd("01/"+Substr(MV_PAR01,1,2)+"/"+Substr(MV_PAR01,3,4))),1,3)+"/"+Substr(MV_PAR01,3,4)
	
	TRAB->(dbGoTop())
	
	While TRAB->(!Eof())

		// Traz o departamento do usuário requisitante

		cCodEst	:= TRAB->QUANTEST
		cEstado	:= TRAB->ESTADO
		cValApr := GetMv('CI_VLRUFRM')//TRAB->VALUNT

		If TRAB->TIPO = '1'
			cTotEst1	:= TRAB->QUANTEST // TRAB->TOTEST
		ElseIf TRAB->TIPO = '2'
			cTotEst2	:= TRAB->QUANTEST // TRAB->TOTEST
		EndIf

		aAdd(aAPREST, { cCodEst, cEstado, cTotEst1, cTotEst2, cTotEst1+cTotEst2, cValApr } )

		cContEmp++
		TRAB->(dBSkip())

	End

	For _nI:=1 to Len(aAPREST)

		cTotCap	+= aAPREST[_nI][3]
		cTotEmp	+= aAPREST[_nI][4]
		cTotGer	+= aAPREST[_nI][5]
		cValApr := aAPREST[_nI][6]

		cPlan += '	<TR> '
		cPlan += '			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" HEIGHT=19 ALIGN=LEFT><FONT FACE="Calibri" COLOR="#000000">'+aAPREST[_nI][2]+'</FONT></TD> '
		cPlan += '			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000" ALIGN=RIGHT BGCOLOR="#C6D9F1" SDVAL="191" SDNUM="1046;1046;#.##0"><FONT FACE="Calibri" COLOR="#000000">'+TransForm(aAPREST[_nI][3],"@E 999,999,999.99")+'</FONT></TD> '
		cPlan += '			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT BGCOLOR="#C6D9F1" SDVAL="83" SDNUM="1046;1046;#.##0"><FONT FACE="Calibri" COLOR="#000000">'+TransForm(aAPREST[_nI][4],"@E 999,999,999.99")+'</FONT></TD> '
		cPlan += '			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="274" SDNUM="1046;1046;#.##0"><FONT FACE="Calibri" COLOR="#000000">'+TransForm(aAPREST[_nI][5],"@E 999,999,999.99")+'</FONT></TD> '
		
		cPlan += '		</TR> '

		li++

	Next _nI


cPlan += '		<TR> '
cPlan += '			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" HEIGHT=19 ALIGN=LEFT><FONT FACE="Calibri" COLOR="#000000">TOTAL</FONT></TD> '
cPlan += '			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="71013" SDNUM="1046;1046;#.##0"><FONT FACE="Calibri" COLOR="#000000">'+TransForm(cTotCap,"@E 999,999,999.99")+'</FONT></TD> '
cPlan += '			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="12824" SDNUM="1046;1046;#.##0"><FONT FACE="Calibri" COLOR="#000000">'+TransForm(cTotEmp,"@E 999,999,999.99")+'</FONT></TD> '
cPlan += '			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT SDVAL="83837" SDNUM="1046;1046;#.##0"><FONT FACE="Calibri" COLOR="#000000">'+TransForm(cTotGer,"@E 999,999,999.99")+'</FONT></TD> '
cPlan += '			<TD ALIGN=LEFT><FONT FACE="Calibri" COLOR="#000000"><BR></FONT></TD> '
cPlan += '			<TD ALIGN=LEFT><FONT FACE="Calibri" COLOR="#000000"><BR></FONT></TD> '
cPlan += '			<TD ALIGN=LEFT><FONT FACE="Calibri" COLOR="#000000"><BR></FONT></TD> '
cPlan += '		</TR> '
cPlan += '		<TR> '
cPlan += '			<TD HEIGHT=17 ALIGN=LEFT><BR></TD> '
cPlan += '			<TD ALIGN=RIGHT VALIGN=BOTTOM SDNUM="1046;1046;#.##0"><BR></TD> '
cPlan += '			<TD ALIGN=RIGHT VALIGN=BOTTOM SDNUM="1046;1046;#.##0"><BR></TD> '
cPlan += '			<TD ALIGN=RIGHT VALIGN=BOTTOM SDNUM="1046;1046;#.##0"><BR></TD> '
cPlan += '			<TD ALIGN=LEFT><BR></TD> '
cPlan += '			<TD ALIGN=LEFT><BR></TD> '
cPlan += '			<TD ALIGN=LEFT><BR></TD> '
cPlan += '		</TR> '
cPlan += '		<TR> '
cPlan += '			<TD HEIGHT=19 ALIGN=RIGHT VALIGN=BOTTOM><B><FONT FACE="Calibri" COLOR="#000000">COMPETENCIA: </FONT></B></TD> '
cPlan += '			<TD ALIGN=RIGHT VALIGN=BOTTOM SDVAL="43739" SDNUM="1046;1046;MMM/AA"><B><FONT FACE="Calibri" COLOR="#000000">'+cMesExt+'</FONT></B></TD> '
cPlan += '			<TD ALIGN=CENTER VALIGN=BOTTOM>Total Aprendizes</TD> '
cPlan += '			<TD ALIGN=RIGHT VALIGN=BOTTOM SDVAL="83837" SDNUM="1046;1046;#.##0">'+TransForm(cTotGer,"@E 999,999,999.99")+'</TD> '
cPlan += '			<TD ALIGN=LEFT><BR></TD> '
cPlan += '			<TD ALIGN=LEFT><BR></TD> '
cPlan += '			<TD ALIGN=LEFT><BR></TD> '
cPlan += '		</TR> '
cPlan += '		<TR> '
cPlan += '			<TD HEIGHT=20 ALIGN=RIGHT VALIGN=BOTTOM><B><FONT FACE="Calibri" COLOR="#000000"> TOTAL DE UF: </FONT></B></TD> '
cPlan += '			<TD ALIGN=RIGHT VALIGN=BOTTOM SDVAL="13301" SDNUM="1046;1046;#.##0"><B><FONT FACE="Calibri" COLOR="#000000">'+TransForm(cContEmp,"@E 999,999,999.99")+'</FONT></B></TD> '
cPlan += '			<TD ALIGN=CENTER VALIGN=BOTTOM SDNUM="1046;1046;#.##0">Valor por aprendiz - R$</TD> '
cPlan += '			<TD ALIGN=RIGHT VALIGN=BOTTOM SDVAL="8,27" SDNUM="1046;0;#.##0,00 ;-#.##0,00 ">'+TransForm(cValApr,"@E 999,999,999.99")+' </TD> '
cPlan += '			<TD ALIGN=LEFT><BR></TD> '
cPlan += '			<TD ALIGN=LEFT SDNUM="1046;1046;0,00"><BR></TD> '
cPlan += '			<TD ALIGN=LEFT><BR></TD> '
cPlan += '		</TR> '
cPlan += '		<TR> '
cPlan += '			<TD HEIGHT=19 ALIGN=LEFT><BR></TD> '
cPlan += '			<TD ALIGN=LEFT><BR></TD> '
cPlan += '			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=CENTER VALIGN=BOTTOM BGCOLOR="#FFFF00" SDNUM="1046;1046;#.##0"><B><FONT FACE="Calibri" COLOR="#000000">VALOR A REPASSAR - R$</FONT></B></TD> '
cPlan += '			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" ALIGN=RIGHT VALIGN=BOTTOM BGCOLOR="#FFFF00" SDVAL="693331,99" SDNUM="1046;1046;#.##0,00"><B><FONT FACE="Calibri" COLOR="#000000">'+TransForm(cTotGer*cValApr,"@E 999,999,999.99")+'</FONT></B></TD> '
cPlan += '			<TD ALIGN=LEFT><BR></TD> '
cPlan += '			<TD ALIGN=LEFT><BR></TD> '
cPlan += '			<TD ALIGN=LEFT><BR></TD> '
cPlan += '		</TR> '

cPlan += '	</TBODY> '
cPlan += '</TABLE> '
cPlan += '<!-- ************************************************************************** --> '
cPlan += '</BODY> '
cPlan += '</HTML>'

	TRAB->(dbCloseArea())

	If mv_par02==1		// Gera planilha
		GeraPlan()
	EndIf

Return


Static Function GeraPlan()

// Grava linha a linha no arquivo XLS
xAddToFile( cPlan, cCmd )

IncProc('Gerando Planilha....')

CpyS2T(cDirDocs+"\"+cArquivo+".xls",cTempPath,.T.)

xFileUpLoad(cTempPath+cArquivo+".xls")

oExcelApp := MsExcel():New()
oExcelApp:WorkBooks:Open(cTempPath+cArquivo+".xls")
oExcelApp:SetVisible(.T.)

Ferase( cDirDocs+"\"+cArquivo+".xls" )

Return

Static Function CabPlan()

cPlan := '<HTML><HEAD><TITLE></TITLE>'
cPlan += '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">'
cPlan += '<META content="text/html; charset=windows-1252" http-equiv=Content-Type>'
cPlan += '<META name=GENERATOR content="MSHTML 9.00.8112.16457"></HEAD>'

cPlan += '<BODY TEXT="#000000"> '
cPlan += '<TABLE FRAME=VOID CELLSPACING=0 COLS=7 RULES=NONE BORDER=0> '
cPlan += '	<COLGROUP><COL WIDTH=164><COL WIDTH=113><COL WIDTH=166><COL WIDTH=141><COL WIDTH=65><COL WIDTH=71><COL WIDTH=65></COLGROUP> '
cPlan += '	<TBODY> '

cPlan += '		<TR> '
cPlan += '		</TR> '

cPlan += '		<TR> '
cPlan += '			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" WIDTH=164 HEIGHT=38 ALIGN=CENTER VALIGN=MIDDLE BGCOLOR="#8EB4E3"><B><FONT FACE="Calibri" COLOR="#17375E">UF</FONT></B></TD> '
cPlan += '			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" WIDTH=113 ALIGN=CENTER VALIGN=MIDDLE BGCOLOR="#8EB4E3"><B><FONT FACE="Calibri" COLOR="#17375E">QTDE APRENDIZ CAPACITADOR</FONT></B></TD> '
cPlan += '			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" WIDTH=166 ALIGN=CENTER VALIGN=MIDDLE BGCOLOR="#8EB4E3"><B><FONT FACE="Calibri" COLOR="#17375E">QTDE APRENDIZ EMPREGADOR</FONT></B></TD> '
cPlan += '			<TD STYLE="border-top: 1px solid #000000; border-bottom: 1px solid #000000; border-left: 1px solid #000000; border-right: 1px solid #000000" WIDTH=141 ALIGN=CENTER VALIGN=MIDDLE BGCOLOR="#8EB4E3"><B><FONT FACE="Calibri" COLOR="#17375E">TOTAL APRENDIZES</FONT></B></TD> '
cPlan += '			<TD WIDTH=65 ALIGN=LEFT><BR></TD> '
cPlan += '			<TD WIDTH=71 ALIGN=LEFT><BR></TD> '
cPlan += '			<TD WIDTH=65 ALIGN=LEFT><BR></TD> '
cPlan += '		</TR> '


// Grava linha a linha no arquivo XLS
xAddToFile( cPlan, cCmd )

cPlan := ""

Return


Static Function xAddToFile( cLog, cToFile )

Local nHdl  := -1
Local cBuff := cLog

	If File( cToFile )

	nHdl := FOpen( cToFile, 1 )

		If nHdl >= 0

		FSeek( nHdl, 0, 2 )

		EndIf

	Else

	nHdl := FCreate( cToFile )

	EndIf

	If nHdl >= 0

	FWrite( nHdl,  cBuff, Len( cBuff ) )

	EndIf

FClose( nHdl )

Return

Static Function ValidPerg( cPerg )
	Local aArea := GetArea(),;
		aRegs := {},;
		i, j

	DbSelectArea( "SX1" )
	DbSetOrder( 1 )

	cPerg := PadR( cPerg,10 )

	AAdd( aRegs, { cPerg,"01","Competência?"	,"","","mv_ch1","C",6,0,0,"G","","mv_par01",""	 ,""   ,""   ,"","",""   ,""   ,""   ,"","","","","","","","","","","","","","","","","","","","","","" } )
	AAdd( aRegs, { cPerg,"02","Gera Planilha  ?","","","mv_ch2","N",1,0,2,"C","","mv_par02","Sim","Sim","Sim","","","Nao","Nao","Nao","","","","","","","","","","","","","","","","","","","","","","" } )


	For i := 1 TO Len( aRegs )
		If !DbSeek( cPerg + aRegs[i,2] )
			RecLock( "SX1", .T. )
			For j := 1 TO FCount()
				If j <= Len( aRegs[i] )
					FieldPut( j, aRegs[i,j] )
				EndIf
			Next
			MsUnlock()
		EndIf
	Next

	RestArea( aArea )

Return

User Function CCAD_VU()

	Local nValUnt := GetMv('CI_VLRUFRM')

	DEFINE MSDIALOG oDlgMain TITLE "Parametro" PIXEL FROM 015,015 TO 160,400
	DEFINE FONT oFont   NAME "Arial" SIZE 0, -12
	DEFINE FONT oBold2  NAME "Arial" SIZE 0, -12 BOLD
		@ 010,010 SAY OemToAnsi("Definir valor a ser pago a FRM.")	SIZE 350,010 PIXEL OF oDlgMain FONT oFont
		@ 027,010 SAY "Valor"				SIZE 100,010 PIXEL OF oDlgMain FONT oFont
		@ 025,125 MSGET oVar	VAR nValUnt	SIZE 060,010 PIXEL OF oDlgMain PICTURE "@E 9,999.99"
		@ 050,102 BUTTON "&Confirma"   		SIZE 040,015 PIXEL ACTION EVAL({|| lTudook:= .T. , oDlgMain:End() })
		@ 050,148 BUTTON "&Cancelar"   		SIZE 040,015 PIXEL ACTION EVAL({|| lTudook:= .F. , oDlgMain:End() })
	ACTIVATE MSDIALOG oDlgMain  CENTERED

	If lTudook
		PutMv("CI_VLRUFRM",nValUnt)
	EndIf

Return

User Function CCAD_ALT() // Altera competência

	LOCAL oScroll 	:= NIL

	LOCAL nTop 		:= 5
	LOCAL n 		:= 0
	LOCAL cGet 		:= ""
	LOCAL cPict 	:= ""
	LOCAL cVar 		:= ""

	Local oLbx1 	:= NIL
	Local aTitulo 	:= {}
	Local nOpcA    	:= 0
	Local nTotApr   := 0
    Local nValTotal := 0
    Local aButtons  := {}
	
	PRIVATE bGet 	:= NIL
	PRIVATE oGet 	:= NIL
	PRIVATE oDlg 	:= NIL
	PRIVATE cTitulo := "REPASSE"
	PRIVATE aSay 	:= {}
	PRIVATE cGetNUM := Space(06)

	If ZCC->ZCC_STATUS <> '1'
		MsgAlert('Status do registro não permite alteração',FunName()+' - '+ProcName())
		Return .F.
	EndIf

	cGetNUM	:= ZCC->ZCC_IDREP

	If ZCD->(dBSeek(xFilial('ZCD')+ZCC->ZCC_IDREP))
		While 	!ZCD->(Eof()) .And.;
	 		ZCD->ZCD_FILIAL+ZCD->ZCD_IDREP = ZCC->ZCC_FILIAL+ZCC->ZCC_IDREP

			SA1->(dBSetOrder(1))
			SA1->(dBSeek(xFilial("SA1")+ZCD->ZCD_CLIENT+ZCD->ZCD_LOJA))
			
			nTotApr += ZCD->ZCD_QTDE
			
			aAdd(aTitulo,{	Alltrim(STR(ZCD->ZCD_QTDE)) ,;
							Transform(ZCD->ZCD_VALOR	,"@E 99,999,999,999.99"),;
							Alltrim(Transform(ZCD->ZCD_QTDE * GetMv('CI_VLRUFRM'),"@E 99,999,999,999.99")),;
							ZCD->ZCD_CLIENT,;
							ZCD->ZCD_LOJA,;
							SA1->A1_NREDUZ,;
							ZCD->ZCD_TIPTIT,;
							ZCD->ZCD_UNREP,;
							DTOC(ZCD->ZCD_VENCTO),;
							DTOC(ZCD->ZCD_EMISSA),;
							ZCD->ZCD_RAZAOS,;
							ZCD->ZCD_CODCTR,;
						    ZCD->ZCD_IDLCTR,;
						    ZCD->ZCD_NUM })

			ZCD->(dBSkip())
		EndDo
	Else
		aAdd(aTitulo,{	"",;
						"",;
						"",;
						"",;
						"",;
						"",;
						"",;
						"",;
						"",;
						"",;
						"",;
						"",;
						""})
	EndIf
	
	nValTotal := nTotApr * GetMv('CI_VLRUFRM')

	aSize := MsAdvSize(.F.)
	DEFINE MSDIALOG oDlg TITLE cTitulo FROM aSize[7],0 To aSize[6],aSize[5] 	OF oDlg PIXEL
	
	Aadd( aButtons, {"HISTORIC", {|| U_CRELK05A()}, "Histórico...", "Rel. Analitico" , {|| .T.}} )  
	
	@ 033,002 TO aSize[4],0192 LABEL "Repasse - Sintético"  		OF oDlg PIXEL // 219
	@ 033,195 TO aSize[4],aSize[6] LABEL "Repasse - Analítico"   	OF oDlg PIXEL // 348

	//scroll box Sintetico
	@ 042,006 SCROLLBOX oScroll HORIZONTAL VERTICAL SIZE aSize[4]-46,182 OF oDlg BORDER
	oDlg:lMaximized := .T. //Maximiza a janela
	oDlg:lCentered 	:= .T. // Centraliza a tela

	If !ZCC->(Eof())

		aAdd(aSay,{"Competencia " ,"C" ,06 ,00 ,"ZCC->ZCC_COMPET" ,"@!" ,.t.})
		aAdd(aSay,{"ID Repasse  " ,"C" ,09 ,00 ,"ZCC->ZCC_IDREP " ,"@!" ,.t.})
		aAdd(aSay,{"Tipo Repasse" ,"C" ,03 ,00 ,"ZCC->ZCC_TIPREP" ,"@!" ,.t.})
		aAdd(aSay,{"Prefixo Tit." ,"C" ,03 ,00 ,"ZCC->ZCC_PFXREP" ,"@!" ,.t.})
		aAdd(aSay,{"Vencto Repas" ,"D" ,08 ,00 ,"ZCC->ZCC_VENCTO" ,"99/99/9999" ,.f.})
		aAdd(aSay,{"Emissao Rep." ,"D" ,08 ,00 ,"ZCC->ZCC_EMISSA" ,"99/99/9999" ,.t.})
		aAdd(aSay,{"Val. Unit.  ", "N", 16, 2, "ZCC->ZCC_VALUNT", "@E 9,999,999,999,999.99",.t.})
		aAdd(aSay,{"Total Apr.  ", "N", 16, 4, "nTotApr","@!",.t.})
		aAdd(aSay,{"Val. Total"  , "N", 04, 2, "nValTotal","@@E 9,999,999,999,999.99",.t.})
		aAdd(aSay,{"Fornecedor  " ,"C" ,06 ,00 ,"ZCC->ZCC_FORNRE" ,"@!" ,.t.})
		aAdd(aSay,{"Loja        " ,"C" ,02 ,00 ,"ZCC->ZCC_LOJA  " ,"@!" ,.t.})
		aAdd(aSay,{"Tipo Titulo " ,"C" ,03 ,00 ,"ZCC->ZCC_TIPTIT" ,"@!" ,.t.})
		aAdd(aSay,{"Produto     " ,"C" ,15 ,00 ,"ZCC->ZCC_PRODRE" ,"@!" ,.t.})
		aAdd(aSay,{"Documento	" ,"C" ,09 ,00 ,"ZCC->ZCC_NUMDOC" ,"@!" ,.f.})
		aAdd(aSay,{"Serie		" ,"C" ,03 ,00 ,"ZCC->ZCC_SERIE"  ,"@!" ,.f.})
		aAdd(asay,{"ID Fluig	" ,"C" ,08 ,00 ,"ZCC_IDFLUI"	  ,"@!" ,.t.})

		For n:=1 TO Len(aSay)
			bGet := &("{|| '"+aSay[n,1]+"'}")
			cVar := aSay[n,5]
			cGet  := "{|u| iif(PCount()>0,"+cVar+":=u,"+cVar+")}"
			cPict := aSay[n,6]
			lRead := aSay[n,7]
			TSay():New(nTop,5,bGet,oScroll,,,.F.,.F.,.F.,.T.,,,GetTextWidth(0,Trim(aSay[n,1])),15,.F.,.F.,.F.,.F.,.F.)
			oGet:=TGet():New(nTop-2,40,&cGet,oScroll,,7,cPict,,,,,.F.,,.T.,,.F.,,.F.,.F.,,lRead,.F.,,(cVar),,,,.T.)
			nTop+=11
		Next n

		//list box Analíticos
		@ 046,199 LISTBOX oLbx1 FIELDS HEADER ;
			"Qtd. Apr.", "Valor Faturamento", "Valor Repasse", ;
			"Cliente", "Tipo Tit.","Num. Tit.","Vencto.", "Emissão", "Razão Social", "Contrato", "ID Local Contrato" ;
			SIZE aSize[5]-350,aSize[4]-50 OF oDlg PIXEL 

		oLbx1:SetArray( aTitulo )
		oLbx1:bLine := {|| {	aTitulo[oLbx1:nAt,01],;
								aTitulo[oLbx1:nAt,02],;
								aTitulo[oLbx1:nAt,03],;
								aTitulo[oLbx1:nAt,04],;
								aTitulo[oLbx1:nAt,07],;
								aTitulo[oLbx1:nAt,14],;
								aTitulo[oLbx1:nAt,09],;
								aTitulo[oLbx1:nAt,10],;
								aTitulo[oLbx1:nAt,11],;
								aTitulo[oLbx1:nAt,12],;
								aTitulo[oLbx1:nAt,13]}}

	EndIf

	ACTIVATE MSDIALOG oDlg CENTER ON INIT EnchoiceBar(oDlg,{||nOpcA:=1,oDlg:End()},{||oDlg:End()},,@aButtons)

	// Grava dados
	If nOpcA == 1
		If RecLock("ZCC",.F.)
			ZCC->ZCC_VENCTO := ZCC->ZCC_VENCTO
			ZCC->ZCC_NUMDOC := ZCC->ZCC_NUMDOC
			ZCC->ZCC_SERIE  := ZCC->ZCC_SERIE
			MsUnlock()
			MsgInfo('Registro atualizado com sucesso.',FunName()+' - '+ProcName())
		Else
			MsgAlert('Não foi possivel gravar alteração.',FunName()+' - '+ProcName())
		EndIf
	EndIf

Return

Static Function xFileUpLoad(xFile)
	Local xRetGed		:= 0
	Local _nI			:= 0
	CALIAS := "ZCC"
	//DbSelectArea("SC7")
	//DbSetOrder(1)
	//If DbSeek(xFilial("SC7")+cNumPed) //Posiciona no Pedido de Compras que esta sendo Impresso

		//Caminho do arquivo e Arquivo PDF
		//_cArq := cPtPdf+cNumPed+".pdf" //c:\spool\XXXX.pdf
		_cArq	:= xFile
		
		//Posiciona na SX2 para pegar o UNICO (chave do IDECM)
		//DbSelectArea("SX2")
		//DbSetOrder(1)
		//DbSeek(CALIAS)
		cIdECM:= &(CALIAS+"->("+TRIM(FWX2Unico(CALIAS))+")")
		aStrChave	:= StrTokArr(FwSX2Util():GetSX2data(cAlias, {"X2_DISPLAY"})[1][2],"+")	
		aVarGets:= {SPACE(250),SPACE(250),"",""}	
	
		// Monta as palavras chaves
		aEval(aStrChave,{|x|  aVarGets[3]+= TRIM(RetTitle(x))+ ":" + TRIM(&(cAlias+"->("+TRIM(x)+")")) + ","  })
	
		IF RIGHT(aVarGets[3],1)==","
			aVarGets[3]:= LEFT(aVarGets[3],LEN(aVarGets[3])-1)
		ENDIF 
/*
		FWGedFindId
		A estrutura é: 
		[n][01] ExpN:ExternalId 
		[n][02] ExpC:DocumentId 
		[n][03] ExpC:Descrição do documento 
		[n][04] ExpC:palavras chaves 
		[n][05] ExpC:nome fisico do arquivo 
		[n][06] ExpN:versão 
		[n][07] ExpC:comentários 
		[n][08] ExpC:tipo do documento 
		[n][09] ExpN:TopicId 
		[n][10] ExpN:IconId
*/
		//Função para buscar Documentos vinculados ao Pedido de Compras
		//cIdECM = chave Unica da tabela SC7
		xRetGedID := FWGedFindId(cIdECM)
		
		If !Empty(xRetGedID) //Se encontrou registros relacionados ao Pedido faz a Exclusão para apos realizar a nova Inclusão
			For _nI := 1 to Len(xRetGedID)
				//If alltrim(xRetGedID[_nI,5]) == (cNumPed+".pdf") //localiza o nome fisico para apagar somente ele na chave principal
				If alltrim(xRetGedID[_nI,5]) == (xFile)
					Processa({|| FWGedDelId(xRetGedID[_nI,2])  },"Realizando exclusão do arquivo, aguarde...")
				EndIf
			Next
		EndIf
		
		Processa({|| xRetGed:= FwGedDocument(TRIM(_cArq),;
													CALIAS,;
													TRIM(cIdECM),;
													"Repasse FRM",;
													TRIM(aVarGets[3]),;
													"Repasse FRM")},"Realizando upload do arquivo, aguarde...")
		IF xRetGed < 0	
			MSGALERT("Não foi possivel adiconar o arquivo!",FunName()+' - '+ProcName())
		ENDIF				
	//EndIf

Return

/*/{Protheus.doc} CCADK05
Valida o estorno dos Repasses
@author
@since 21/07/2020
@version 12.1.25
@type user function
/*/
Static Function EstornoOK(cRepaPR)

local lRet 	    := .T.
local cAliasSE1 := ""
local cQuery    := ""

//Valida se o repasse ainda esta em aberto
If ZCC->ZCC_STATUS <> '1'
	cIdRepNEst += "/"+ALLTRIM(ZCC->ZCC_IDREP)
	lRet := .F.
endif

//Se for estorno de repasse a receber valida se o titulo provisório ainda esta aberto
if lRet .and. cRepaPR=="R"

 	cAliasSE1  := GetNextAlias()
	
	cQuery := " SELECT "
	cQuery += " E1_XIDREP, E1_BAIXA FROM " + RetSqlName("SE1") 
	cQuery += " WHERE "
	cQuery += " D_E_L_E_T_='' "
	cQuery += " AND E1_FILIAL='"+XFILIAL("SE1")+"' "
	cQuery += " AND E1_XIDREP='"+ALLTRIM(ZCC->ZCC_IDREP)+"' "
	cQuery += " AND E1_BAIXA<>'' "

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSE1,.T.,.T.)
	
	if (cAliasSE1)->(!EOF()) 
		cIdRepNEst += "/"+ALLTRIM(ZCC->ZCC_IDREP)
		lRet := .F.
	endif
	
	(cAliasSE1)->(DbCloseArea())

endif

return(lRet)

/*/{Protheus.doc} COMP_REC
Gera Titulo a receber do repasse
@author
@since 06/10/2020
@version 12.1.25
@type user function
/*/
User Function COMP_REC()

local cPerg  	  := PadR("CCADKGCREP", Len(SX1->X1_GRUPO)) 
Local oWBrowse1   := nil
Local aWBrowse1   := {}
Local oCheckBo1   := nil
Local lCheckBo1   := .F.
local _oOk 	   	  := LoadBitmap( GetResources(), "LBOK")
local _oNo 		  := LoadBitmap( GetResources(), "LBNO") 
local lProcessa   := nil

Private _cUF      := ""
Private nHndERP   := AdvConnection()

Static oDlg

ValSX1P1(cPerg)

if pergunte(cPerg,.T.)

	//Busca da UF filial logada
	DbSelectArea("SM0")
	SM0->(DbSetOrder(01))
	SM0->(DbSeek(cEmpAnt+cFilAnt))
	_cUF := SM0->M0_ESTCOB

	//Busca movimentos do repasse
    aWBrowse1 := BuscaRepasse(MV_PAR01,MV_PAR02)

	if len(aWBrowse1)

		DEFINE MSDIALOG oDlg TITLE "Competência: " + DTOC(MV_PAR01) + " até " + DTOC(MV_PAR02) FROM 000, 000  TO 500, 900 COLORS 0, 16777215 PIXEL    

			@  004, 003 LISTBOX oWBrowse1 VAR cVarQ Fields HEADER " ","UFOri","Cliente","Loja","Nome","CNPJ","Vcto","Qtde Rep","Valor Rep", "Compet" SIZE 442, 220 ON DBLCLICK (aWBrowse1:=CA710Troca(oWBrowse1:nAt,aWBrowse1),oWBrowse1:Refresh()) ON RIGHT CLICK ListBoxAll(nRow,nCol,@oWBrowse1,_oOk,,@aWBrowse1) NOSCROLL OF oDlg PIXEL
			@  232, 006 CHECKBOX oCheckBo1 VAR lCheckBo1 PROMPT "Marca/desmarca todos" SIZE 100, 008 OF oDlg PIXEL ON CLICK (AEval(aWBrowse1, {|z| z[1] := lCheckBo1}), oWBrowse1:Refresh())
			oWBrowse1:SetArray(aWBrowse1)
			oWBrowse1:bLine := { || {If(aWBrowse1[oWBrowse1:nAt,1],_oOk,_oNo),aWBrowse1[oWBrowse1:nAt,2],aWBrowse1[oWBrowse1:nAt,3],aWBrowse1[oWBrowse1:nAt,4],aWBrowse1[oWBrowse1:nAt,5],aWBrowse1[oWBrowse1:nAt,6],aWBrowse1[oWBrowse1:nAt,7],aWBrowse1[oWBrowse1:nAt,8],Transform(aWBrowse1[oWBrowse1:nAt,9],"@E 99,999,999,999.99"),aWBrowse1[oWBrowse1:nAt,10]}} 

			@ 230, 345 BUTTON oButCancela PROMPT "Cancela" SIZE 047, 014 OF oDlg ACTION (lProcessa  := .F.,oDLg:End()) PIXEL
			@ 230, 398 BUTTON oButProcessa PROMPT "Processa" SIZE 047, 014 OF oDlg ACTION (lProcessa  := .T.,oDLg:End()) PIXEL

		ACTIVATE MSDIALOG oDlg CENTERED   

		if lProcessa

			if len(aWBrowse1) > 0
				Processa({|| GeraSE1(aWBrowse1)},"Processando...")
			endif

		endif

	 else

		MsgInfo("Não existem valores a repassar no período informado !")

	 endif

endif 


return

/*/{Protheus.doc} ValSX1P1
//TODO Descrição auto-gerada.
@author marcelo.moraes
@since 05/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function ValSX1P1(cPerg)

Local _aArea := getarea()
Local aRegs := {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)

cPerg := PADR(cPerg,10)

aAdd(aRegs,{cPerg,"01","Período de:","","","mv_ch1" ,"D",8,0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"02","Período até: ","","","mv_ch2" ,"D",8,0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

For i:=1 to Len(aRegs)
	If !dbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j <= Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next

RestArea(_aArea)

/*/{Protheus.doc} ValSX1P2
//TODO Descrição auto-gerada.
@author marcelo.moraes
@since 05/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function ValSX1P2(cPerg)

Local _aArea := getarea()
Local aRegs := {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)

cPerg := PADR(cPerg,10)

aAdd(aRegs,{cPerg,"01","CNPJ:","","","mv_ch1" ,"C",14,0,0,"G","","MV_PAR01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"02","Competencia de:","","","mv_ch2" ,"C",6,0,0,"G","","MV_PAR02","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"03","Competencia até:","","","mv_ch3" ,"C",6,0,0,"G","","MV_PAR03","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

For i:=1 to Len(aRegs)
	If !dbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j <= Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next

RestArea(_aArea)

/*/{Protheus.doc} BuscaRepasse
//TODO Descrição auto-gerada.
@author marcelo.moraes
@since 05/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function BuscaRepasse(dDataDe,dDataAte)

local aRet        := {}
Local cBcoOra     := Alltrim(SuperGetMv("CI_BANCORA",.F.,"ORACLE/dev"))
Local cSrvOra     := Alltrim(SuperGetMv("CI_SERVORA",.F.,"localhost"))
Local nPtaOra  	  := SuperGetMv("CI_PORTORA",.F.,9335)
local _cAliasOra  := GetNextAlias()
local cQuery   	  := ""
local nReg        := 0
local cCliente    := ""
local cLoja       := ""
local cNomeCli    := ""
local cCNPJ       := ""

// Abre conexão com o Oracle
nConOra := TCLink(cBcoOra,cSrvOra,nPtaOra)
	
If nConOra >= 0

	tcSetConn(nConOra)

	_cAliasOra := GetNextAlias()

	cQuery += " SELECT " 
	cQuery += " REPMESANO COMPET,REPORIGREP ORIGREP, REPDATVCT VCTO, COUNT(repvlrrep) QTDREP,SUM(repvlrrep) VLRREP "
	cQuery += " FROM (SELECT "
	cQuery += " REPORIGREP, "
	cQuery += " to_char(repmesano,'YYYYMMDD') repmesano, "
	cQuery += " to_char(REPDATVCT,'YYYYMMDD') REPDATVCT, "
	cQuery += " repvlrrep "
	cQuery += " FROM ICNREPASSE_REALIZADO " 
	cQuery += " WHERE " 
	cQuery += " REPDESTREP ='"+alltrim(_cUF)+"') TABELA " 
	cQuery += " WHERE " 
	cQuery += " repmesano BETWEEN '"+DTOS(dDataDe)+"' AND '"+DTOS(dDataAte)+"' " 
	cQuery += " GROUP BY REPMESANO,REPORIGREP,REPDATVCT "
	cQuery += " ORDER BY REPORIGREP,REPDATVCT "

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),_cAliasOra,.T.,.T.)

	While (_cAliasOra)->(!EOF()) 

		AADD(aRet,{.F.,(_cAliasOra)->ORIGREP,;
						"",;
						"",;
						"",;
						"",;
						STOD((_cAliasOra)->VCTO),;
						(_cAliasOra)->QTDREP,;
						(_cAliasOra)->VLRREP,;
						substr((_cAliasOra)->COMPET,5,2)+substr((_cAliasOra)->COMPET,1,4)})

		(_cAliasOra)->(DBSKIP()) 
	end

	(_cAliasOra)->(DbCloseArea())

	TCUnLink(nConOra)
	
endif

//Seta top de RH
tcSetConn(nHndERP)

//Atualiza Cliente/Loja/Nome/CNPJ
if len(aRet)>0
	for nReg:=1 to len(aRet)

		cCliente    := ""
		cLoja       := ""
		cNomeCli    := ""
		cCNPJ       := ""

		//Busca Cliente/Loja
		SX5->(dBSetOrder(1))
		If SX5->(dBSeek(xFilial('SX5')+"W1"+AvKey(aRet[nReg][2],"A1_EST")))
			cCliente := SUBSTR(SX5->X5_DESCRI,1,6)
			cLoja := SUBSTR(SX5->X5_DESCRI,7,2)
		endif
	
		cNomeCli := GetAdvFVal("SA1","A1_NOME",XFILIAL("SA1")+AvKey(cCliente,"A1_COD")+AvKey(cLoja,"A1_LOJA"),1) 
		cCNPJ := GetAdvFVal("SA1","A1_CGC",XFILIAL("SA1")+AvKey(cCliente,"A1_COD")+AvKey(cLoja,"A1_LOJA"),1) 
		
		aRet[nReg][3] := cCliente
		aRet[nReg][4] := cLoja

		if !Empty(cNomeCli)
			aRet[nReg][5] := Alltrim(cNomeCli)
		else
			aRet[nReg][5] := "Cliente não cadastrado!"
		endif

		aRet[nReg][6] := cCNPJ
	next
endif

return(aRet)

/*/{Protheus.doc} GeraSE1
Gera título a receber
@author
@since 06/10/2020
@version 12.1.25
@type user function
/*/
Static Function GeraSE1(aDados)

local nItem 	:= 0
local cTitulo   := ""
local cCNPJ     := ""
local cCliente  := "" 
local cLoja     := "" 
local aTitSE1   := {}
local _cMsg		:= ""
local dBackDat  := Ctod("")
local lAltdata  := nil

Private lMsErroAuto := .F.
Private _aLogSE1  := {}

procregua(len(aDados))

for nItem:=1 to len(aDados)

	IncProc()

	if aDados[nItem][1]

		cTitulo := ""
		_cMsg	:= ""

		cTitulo  := ExistRepasse(aDados[nItem])

		if Empty(cTitulo)
				
				cTitulo := GetSXENum("SE1","E1_NUM")
				ConfirmSX8()

				cCNPJ      := AvKey(aDados[nItem][6],"A1_CGC")
				cCliente   := AvKey(aDados[nItem][3],"A1_COD")
				cLoja      := AvKey(aDados[nItem][4],"A1_LOJA")

				if Empty(cCliente) .or. Empty(cLoja) 

					_cMsg := "Erro! - Cliente ou loja não encontrado !!!"

				else

					lMsErroAuto := .F.
					lAltdata    := .F.

					if aDados[nItem][7] < dDataBase //Caso o vencimento seja menor que a data base do sistema
						dBackDat  := dDataBase
						dDataBase := aDados[nItem][7] //Altera a data base para a data do vencimento 
						lAltdata  := .T.
					endif

					//Gera titulo a receber
					aTitSE1 := {{"E1_PREFIXO" ,ALLTRIM(GetMv("CI_PRXREPC",.F.,"AUT")),Nil},;
					{"E1_NUM" ,cTitulo,Nil},;  
					{"E1_PARCELA" ,"",Nil},;
					{"E1_TIPO" ,ALLTRIM(GetMv("CI_TIPREPC",.F.,"DP")) ,Nil},;
					{"E1_FILIAL" ,xFilial("SE1") ,Nil},;
					{"E1_NATUREZ" ,ALLTRIM(GetMv("CI_NATREPC",.F.,"99999999")),Nil},;
					{"E1_CLIENTE" ,cCliente,Nil},;
					{"E1_LOJA" ,cLoja,Nil},;
					{"E1_XCOMPET" ,aDados[nItem][10],Nil},;
					{"E1_EMISSAO" ,dDataBase,Nil},;
					{"E1_VENCTO" ,aDados[nItem][7],Nil},;
					{"E1_VALOR" ,aDados[nItem][9],Nil }}

					MSExecAuto({|x, y| FINA040(x, y)}, aTitSE1, 3) // 3 – Inclusao, 4 – Alteração, 5 – Exclusão
					
					if lAltdata
						dDataBase := dBackDat //Volta a data base correta
					endif

					If lMsErroAuto
						RollBAckSx8() 
						_cMsg := "Erro! - Execauto - Falha na geração do(s)  titulo(s) a receber"
						//Mostraerro()
					Else
						_cMsg := "Título: "+Alltrim(cTitulo)+" gerado com sucesso!!!"
						GrvMovOrac(cTitulo,_cUF,aDados[nItem][2],MV_PAR01,MV_PAR02,aDados[nItem][7])
					endif

				endif

		else
			_cMsg := "Erro! Movimento já integrado anteriormente !!!, com o título:  " + cTitulo
		endif
		
		aadd(_aLogSE1,{aDados[nItem][2],aDados[nItem][3],aDados[nItem][4],aDados[nItem][5],aDados[nItem][6],aDados[nItem][7],aDados[nItem][9],_cMsg})
		
	endif

next

if len(_aLogSE1) > 0
	RComp_Rec()
endif

return

/*/{Protheus.doc} ExistRepasse
Valida se o movimento pode ser gerado no SE1
@author
@since 06/10/2020
@version 12.1.25
@type user function
/*/
Static Function ExistRepasse(aRegistro)

local cRet       := ""
local cAliasSE1  := GetNextAlias()
local cCliente   := AvKey(aRegistro[3],"A1_COD")
local cLoja      := AvKey(aRegistro[4],"A1_LOJA")
local dVencto    := aRegistro[7]
local nValor     := aRegistro[9]
local cQuery	 := ""

cQuery := " SELECT "
cQuery += " E1_NUM, E1_VALOR FROM " + RetSqlName("SE1") 
cQuery += " WHERE "
cQuery += " D_E_L_E_T_='' "
cQuery += " AND E1_FILIAL='"+XFILIAL("SE1")+"' "
cQuery += " AND E1_CLIENTE='"+cCliente+"' "
cQuery += " AND E1_LOJA='"+cLoja+"' "
cQuery += " AND E1_VALOR="+alltrim(str(nValor))
cQuery += " AND E1_VENCTO='"+DTOS(dVencto)+"' "

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSE1,.T.,.T.)

if (cAliasSE1)->(!EOF()) 
	cRet := (cAliasSE1)->E1_NUM
endif

(cAliasSE1)->(DbCloseArea())

return(cRet)

/*/{Protheus.doc} RComp_Rec
Imprime relatorio log Compensação ICN Receber
@author
@since 06/10/2020
@version 12.1.25
@type user function
/*/
Static Function RComp_Rec()

oReport := ReportDef()  
oReport:PrintDialog()

return

/*/{Protheus.doc} ReportDef
//TODO Definiçãoes do relatório
@author marcelo.moraes
@since 03/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function ReportDef()

Local oReport
Local oSessao1   

SET DATE FORMAT TO "dd/mm/yyyy"
SET CENTURY ON
SET DATE BRITISH

//######################
//##Cria Objeto TReport#
//######################

oReport := TReport():New("CCADK05","Relatório de status - Geração título ICN Receber","",{|oReport| PrintReport(oReport)},"Relatório de status - Geração título ICN Receber")
oReport:lParamPage := .F.   
oReport:SetLandscape(.T.)

//###############
//##Cria Sessao1#
//###############

oSessao1 := TRSection():New(oReport,"Analítico",{"TRB1"})
oSessao1 :SetReadOnly()

TRCell():New(oSessao1,"UFORI" ,'TRB1',"UF",,02,.F.)
TRCell():New(oSessao1,"CLIENTE" ,'TRB1',"Cliente",,06,.F.)
TRCell():New(oSessao1,"LOJA" ,'TRB1',"Loja",,02,.F.)
TRCell():New(oSessao1,"NOMECLI" ,'TRB1',"RazãoSoc",,40,.F.)
TRCell():New(oSessao1,"CNPJ" ,'TRB1',"CNPJ",,14,.F.)
TRCell():New(oSessao1,"VCTO" ,'TRB1',"Vencto",,8,.F.)
TRCell():New(oSessao1,"VALOR" ,'TRB1',"Valor","@E 999,999.99",14,.F.)
TRCell():New(oSessao1,"STATUS" ,'TRB1',"Status",,100,.F.)

Return oReport 

/*/{Protheus.doc} PrintReport
//TODO Descrição auto-gerada.
@author marcelo.moraes
@since 05/09/2018
@version 1.0
@return ${return}, ${return_description}
@param oReport, object, descricao
@type function
/*/
Static Function PrintReport(oReport) 

local aArea	 := GetArea() 
local nItem  := 0

oReport:SetMeter(1)
           
oReport:Section(1):Init()

for nItem:=1 to len(_aLogSE1)

	if oReport:Cancel()
		Exit
	Endif 

	oReport:IncMeter()  

	oReport:Section(1):Cell("UFORI"):SetBlock({|| _aLogSE1[nItem][1] })
	oReport:Section(1):Cell("CLIENTE"):SetBlock({|| _aLogSE1[nItem][2] })
	oReport:Section(1):Cell("LOJA"):SetBlock({|| _aLogSE1[nItem][3] })  
	oReport:Section(1):Cell("NOMECLI"):SetBlock({|| _aLogSE1[nItem][4] }) 
	oReport:Section(1):Cell("CNPJ"):SetBlock({|| _aLogSE1[nItem][5] }) 
	oReport:Section(1):Cell("VCTO"):SetBlock({|| _aLogSE1[nItem][6] }) 
	oReport:Section(1):Cell("VALOR"):SetBlock({|| _aLogSE1[nItem][7] }) 
	oReport:Section(1):Cell("STATUS"):SetBlock({|| _aLogSE1[nItem][8] })

	oReport:Section(1):PrintLine()
	
next

oReport:Section(1):Finish()

RestArea(aArea)

Return  

/*/{Protheus.doc} GrvMovOrac
//TODO Grava tabela ZZB movimentos (analítico) do oracle que somados refletem o valor do titulo a receber
@author marcelo.moraes
@since 03/09/2018
@version 1.0
@return ${return}, ${return_description}
@param cPerg, characters, descricao
@type function
/*/
Static Function GrvMovOrac(cTitulo,_cUF,_cUFOrig,dDataDe,dDataAte,dVecto)

Local cBcoOra     := Alltrim(SuperGetMv("CI_BANCORA",.F.,"ORACLE/dev"))
Local cSrvOra     := Alltrim(SuperGetMv("CI_SERVORA",.F.,"localhost"))
Local nPtaOra  	  := SuperGetMv("CI_PORTORA",.F.,9335)
local _cAliasOra  := GetNextAlias()
local cQuery   	  := ""
local adadosOra   := {}
local nReg		  := 0

// Abre conexão com o Oracle
nConOra := TCLink(cBcoOra,cSrvOra,nPtaOra)
	
If nConOra >= 0

	tcSetConn(nConOra)

	_cAliasOra := GetNextAlias()

	cQuery += " SELECT * FROM (SELECT " 
	cQuery += " to_char(repmesano,'YYYYMMDD') repmesano, "
	cQuery += " to_char(repdatrep,'YYYYMMDD') repdatrep, "
	cQuery += " repvlrrep, "
	cQuery += " REPDESTREP, "
	cQuery += " reporigrep, "
	cQuery += " repcpf, "
	cQuery += " repcnpj, "
	cQuery += " to_char(REPDATVCT,'YYYYMMDD') REPDATVCT "
	cQuery += " FROM ICNREPASSE_REALIZADO " 
	cQuery += " WHERE " 
	cQuery += " REPDESTREP = '"+alltrim(_cUF)+"' "
	cQuery += " AND REPORIGREP='"+alltrim(_cUFOrig)+"') TABELA " 
	cQuery += " WHERE " 
	cQuery += " repmesano BETWEEN '"+DTOS(dDataDe)+"' AND '"+DTOS(dDataAte)+"' " 
	cQuery += " AND REPDATVCT='"+DTOS(dVecto)+"' " 

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),_cAliasOra,.T.,.T.)

	While (_cAliasOra)->(!EOF()) 

		AADD(adadosOra,{(_cAliasOra)->repmesano,;
						(_cAliasOra)->repdatrep,;
						(_cAliasOra)->repvlrrep,;
						(_cAliasOra)->REPDESTREP,;
						(_cAliasOra)->reporigrep,;
						(_cAliasOra)->repcpf,;
						(_cAliasOra)->repcnpj,;
						(_cAliasOra)->REPDATVCT})


		(_cAliasOra)->(DBSKIP()) 
	end

	(_cAliasOra)->(DbCloseArea())

	TCUnLink(nConOra)
	
endif

//Seta top de RH
tcSetConn(nHndERP)

for nReg:=1 to len(adadosOra)

	RecLock("ZZB",.T.)
		ZZB->ZZB_FILIAL	:= xFilial('ZZB')
		ZZB->ZZB_NUMTIT := cTitulo
		ZZB->ZZB_MESANO := STOD(adadosOra[nReg][1])
		ZZB->ZZB_DATREP := STOD(adadosOra[nReg][2])
		ZZB->ZZB_VLRREP := adadosOra[nReg][3]
		ZZB->ZZB_DESTRE := adadosOra[nReg][4]
		ZZB->ZZB_ORIGRE := adadosOra[nReg][5]
		ZZB->ZZB_REPCPF := adadosOra[nReg][6]
		ZZB->ZZB_RECNPJ := adadosOra[nReg][7]
		ZZB->ZZB_DATVCT := STOD(adadosOra[nReg][8])
	ZZB->(MsUnLock())

next

return

User Function RetTotApr(cIdRep,cIdLctr, cCodCtr )

Local aArea    := GetArea()
Local nTotApr  := 0
Local cCnpjBB  := AllTrim(GetMv('CI_CNPJBB'))
Local cCnpjCX  := AllTrim(GetMv('CI_CNPJCX'))
Local cTabela  := ""
Local cCompet  := ZCC->ZCC_COMPET

cTabela := GetNextAlias()
BeginSql alias cTabela
       
select count(ZC6_IDFATU)   FATQTDE  from %table:ZC6% WHERE ZC6_IDCONT =  %exp:cCodCtr% AND ZC6_LOCCON = %exp:cIdLctr% AND  ZC6_COMPET = '082020' AND   D_E_L_E_T_ = ''
     
EndSql

(cTabela)->(DbGoTop())

While (cTabela)->(!Eof())

	nTotApr += (cTabela)->FATQTDE
	
	(cTabela)->(dBSkip())

EndDo

(cTabela)->(DbCloseArea())

RestArea(aArea)

Return nTotApr

/*/{Protheus.doc} CCK05CMP
Gera Compensação Repasse a receber
@author
@since 06/10/2020
@version 12.1.25
@type user function
/*/
User Function CCK05CMP()

local aArea		  := GetArea()
local cPerg  	  := PadR("CCADKGCOMP", Len(SX1->X1_GRUPO)) 
local aSA1    	  := {}
Local oButFiltrar
Local oButSair
Local oButComp
Local oGroup1
Local oGroup2
local oDlgComp
Local oWBrowse1   := nil
Local aWBrowse1   := {}
Local oWBrowse2   := nil
Local aWBrowse2   := {}
local _oOk 	   	  := LoadBitmap( GetResources(), "LBOK")
local _oNo 		  := LoadBitmap( GetResources(), "LBNO") 
local _lExibeTela := .T.

ValSX1P2(cPerg)

if pergunte(cPerg,.T.)

	aSA1 := GetAdvFVal("SA1",{"A1_COD","A1_LOJA"} ,XFILIAL("SA1")+AvKey(MV_PAR01,"A1_CGC"),3)

	While _lExibeTela

		aWBrowse1 := BuscaTitPrv(aSA1,MV_PAR02,MV_PAR03)

		if len(aWBrowse1)

			aWBrowse2   := {}

			AADD(aWBrowse2,{.f.,"",;
					"",;
					"",;
					""})
			
			DEFINE MSDIALOG oDlgComp TITLE "Compensação Títulos" FROM 000, 000  TO 540, 1000 COLORS 0, 16777215 PIXEL

				@ 001, 004 GROUP oGroup1 TO 246, 249 PROMPT "Títulos Provisórios" OF oDlgComp COLOR 0, 16777215 PIXEL
				@ 001, 252 GROUP oGroup2 TO 246, 497 PROMPT "Titulo Repasse" OF oDlgComp COLOR 0, 16777215 PIXEL
				
				@  011, 009 LISTBOX oWBrowse1 VAR cVarQ Fields HEADER " ","Título","Compet","Vencto","Valor" SIZE 235, 228 ON DBLCLICK (aWBrowse1:=CA710Troca(oWBrowse1:nAt,aWBrowse1),oWBrowse1:Refresh()) ON RIGHT CLICK ListBoxAll(nRow,nCol,@oWBrowse1,_oOk,,@aWBrowse1) NOSCROLL OF oDlg PIXEL
				oWBrowse1:SetArray(aWBrowse1)
				oWBrowse1:bLine := { || {If(aWBrowse1[oWBrowse1:nAt,1],_oOk,_oNo),aWBrowse1[oWBrowse1:nAt,2],aWBrowse1[oWBrowse1:nAt,3],aWBrowse1[oWBrowse1:nAt,4],Transform(aWBrowse1[oWBrowse1:nAt,5],"@E 99,999,999,999.99")}}
				
				@ 011, 256 LISTBOX oWBrowse2 VAR cVarQ Fields HEADER " ","Título","Compet","Vencto","Valor" SIZE 235, 218 ON DBLCLICK (aWBrowse2:=CA710Troca(oWBrowse2:nAt,aWBrowse2),oWBrowse2:Refresh()) ON RIGHT CLICK ListBoxAll(nRow,nCol,@oWBrowse2,_oOk,,@aWBrowse2) NOSCROLL OF oDlg PIXEL
				oWBrowse2:SetArray(aWBrowse2)
				oWBrowse2:bLine := { || {If(aWBrowse2[oWBrowse2:nAt,1],_oOk,_oNo),aWBrowse2[oWBrowse2:nAt,2],aWBrowse2[oWBrowse2:nAt,3],aWBrowse2[oWBrowse2:nAt,4],Transform(aWBrowse2[oWBrowse2:nAt,5],"@E 99,999,999,999.99")}}	
				
				@ 250, 195 BUTTON oButFiltrar PROMPT "Filtrar" SIZE 053, 013 OF oDlgComp PIXEL ACTION EVAL({|| FilTitPrv(aWBrowse1,aWBrowse2,oWBrowse2,_oOk,_oNo,aSA1) })
				@ 250, 443 BUTTON oButComp PROMPT "Compensar" SIZE 053, 013 OF oDlgComp PIXEL ACTION EVAL({|| CmpTitPrv(aWBrowse1),oDlgComp:End() })
				@ 250, 385 BUTTON oButSair PROMPT "Sair" SIZE 053, 013 OF oDlgComp PIXEL ACTION EVAL({|| _lExibeTela := .F.,oDlgComp:End() })

			ACTIVATE MSDIALOG oDlgComp CENTERED

		else

			msginfo("Não existem títulos provisórios para compensar")
			_lExibeTela := .F.

		endif

	End

endif

RestArea(aArea)

return

/*/{Protheus.doc} FilTitPrv
Preenche listBox com os títulos que poderão substituir os titulos provisórios
@author
@since 06/10/2020
@version 12.1.25
@type user function
/*/
Static Function FilTitPrv(aWBrowse1,aWBrowse2,oWBrowse2,_oOk,_oNo,aSA1)

local nReg        := 0
local nQtSel      := 0
local lContinua   := .T.
local cCompet     := ""

for nReg:=1 to len(aWBrowse1)
	if aWBrowse1[nReg][1]
		nQtSel ++	
	endif		
next

//Caso o usuário tenha selecionado mais de um título provisório por vez não continua
if nQtSel > 1
	lContinua := .F.
	msginfo("Selecione somente um título provisório por vez")
endif

//Caso o usuário não tenha selecionado nenhum título também não continua
if nQtSel == 0
	lContinua := .F.
endif

aWBrowse2 := {}

IF lContinua

	//Busca o título provisório que foi selecionado
	for nReg:=1 to len(aWBrowse1)
		if aWBrowse1[nReg][1]
			cCompet := StrTran( aWBrowse1[nReg][3],"/",) 
			exit
		endif		
	next

	aWBrowse2 := BuscaTitDP(aSA1,cCompet)

	if Empty(aWBrowse2) 

		AADD(aWBrowse2,{.f.,"",;
							"",;
					ctod(""),;
						0})
	endif
else

	AADD(aWBrowse2,{.f.,"",;
						"",;
				ctod(""),;
					0})

endif

oWBrowse2:SetArray(aWBrowse2)
oWBrowse2:bLine := { || {If(aWBrowse2[oWBrowse2:nAt,1],_oOk,_oNo),aWBrowse2[oWBrowse2:nAt,2],aWBrowse2[oWBrowse2:nAt,3],aWBrowse2[oWBrowse2:nAt,4],Transform(aWBrowse2[oWBrowse2:nAt,5],"@E 99,999,999,999.99")}}	
oWBrowse2:Refresh()

return

/*/{Protheus.doc} CmpTitPrv
Compensa título provisório
@author
@since 06/10/2020
@version 12.1.25
@type user function
/*/
Static Function CmpTitPrv(aWBrowse1)

local nQtSel 	:= 0
local lContinua := .T.
local nReg 		:= 0
local nRecno    := 0
local aTitRec   := {}

Private	lMsErroAuto := .F.

for nReg:=1 to len(aWBrowse1)
	if aWBrowse1[nReg][1]
		nQtSel ++	
	endif		
next

//Caso o usuário tenha selecionado mais de um título provisório por vez não continua
if nQtSel > 1
	lContinua := .F.
	msginfo("Selecione somente um título provisório por vez")
endif

//Caso o usuário não tenha selecionado nenhum título também não continua
if nQtSel == 0
	lContinua := .F.
	msginfo("Selecione o título provisório que será Compensado")
endif

if lContinua

	IF !MSGYESNO("Confirma compensação do título  ? ")
		lContinua := .F.	
	endif

endif

if lContinua

	//Busca o título provisório que será excluído
	for nReg:=1 to len(aWBrowse1)
		if aWBrowse1[nReg][1]
			nRecno := aWBrowse1[nReg][6]
			exit
		endif		
	next

	if nRecno > 0

		//Posiciona no titulo provisório para excluir
		SE1->(dbGoto(nRecno))

		aTitRec := {{"E1_PREFIXO" ,SE1->E1_PREFIXO,Nil},;
		{"E1_NUM" ,SE1->E1_NUM,Nil},;
		{"E1_PARCELA" ,SE1->E1_PARCELA,Nil},;
		{"E1_TIPO" ,SE1->E1_TIPO,Nil},;
		{"E1_FILIAL" ,SE1->E1_FILIAL ,Nil},;
		{"E1_NATUREZ" ,SE1->E1_NATUREZ,Nil},;
		{"E1_CLIENTE" ,SE1->E1_CLIENTE,Nil},;
		{"E1_LOJA" ,SE1->E1_LOJA,Nil},;
		{"E1_EMISSAO" ,SE1->E1_EMISSAO,Nil},;
		{"E1_VENCTO" ,SE1->E1_VENCTO,Nil},;
		{"E1_BAIXA" ,DATE(),Nil},;
		{"E1_SALDO" ,0,Nil},;
		{"E1_VALOR" ,SE1->E1_VALOR,Nil },;
		{"E1_XIDREP" ,SE1->E1_XIDREP,Nil }}

		MSExecAuto({|x, y| FINA040(x, y)}, aTitRec, 4) // 3 – Inclusao, 4 – Alteração, 5 – Exclusão

		If lMsErroAuto
			MOSTRAERRO()
		Else
			msginfo("Titulo Compensado com sucesso !!!")
		endif

	endif

endif

return

/*/{Protheus.doc} BuscaTitPrv
Busca títulos provisórios
@author
@since 06/10/2020
@version 12.1.25
@type user function
/*/
Static Function BuscaTitPrv(aSA1,_CompeDe,_CompeAte)

local aRet   	  := {}
local cQuery 	  := ""
local _cAliasSE1  := GetNextAlias()

//Busca todos os títulos provisórios do cliente
cQuery +=" SELECT "
cQuery +=" E1_FILIAL, E1_NUM, E1_XCOMPET, E1_VENCREA, E1_VALOR, R_E_C_N_O_ "
cQuery +=" FROM "+RetSqlName("SE1")
cQuery +=" WHERE "
cQuery +=" D_E_L_E_T_='' "
cQuery +=" AND E1_TIPO='PR' "
cQuery +=" AND E1_CLIENTE='"+aSA1[1]+"' "
cQuery +=" AND E1_LOJA='"+aSA1[2]+"' "
cQuery +=" AND E1_XCOMPET BETWEEN '"+_CompeDe+"' AND '"+_CompeAte+"' "
cQuery +=" AND E1_SALDO > 0 "
cQuery +=" ORDER BY E1_XCOMPET "

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),_cAliasSE1,.T.,.T.)

While (_cAliasSE1)->(!EOF()) 

	AADD(aRet,{.F.,(_cAliasSE1)->E1_NUM,;
					substr((_cAliasSE1)->E1_XCOMPET,1,2)+"/"+substr((_cAliasSE1)->E1_XCOMPET,3,4),;
					STOD((_cAliasSE1)->E1_VENCREA),;
					(_cAliasSE1)->E1_VALOR,;
					(_cAliasSE1)->R_E_C_N_O_})

		(_cAliasSE1)->(DBSKIP()) 
end

(_cAliasSE1)->(DbCloseArea())

return(aRet)

/*/{Protheus.doc} BuscaTitDP
Busca títulos do Repasse
@author
@since 06/10/2020
@version 12.1.25
@type user function
/*/
Static Function BuscaTitDP(aSA1,cCompet)

local aRet   	  := {}
local cQuery 	  := ""
local _cAliasSE1  := GetNextAlias()

//Busca todos os títulos repasse do cliente
cQuery +=" SELECT "
cQuery +=" E1_FILIAL, E1_NUM, E1_XCOMPET, E1_VENCREA, E1_VALOR "
cQuery +=" FROM "+RetSqlName("SE1")
cQuery +=" WHERE "
cQuery +=" D_E_L_E_T_='' "
cQuery +=" AND E1_TIPO='DP' "
cQuery +=" AND E1_CLIENTE='"+aSA1[1]+"' "
cQuery +=" AND E1_LOJA='"+aSA1[2]+"' "
cQuery +=" AND E1_XCOMPET='"+cCompet+"' "
cQuery +=" AND E1_SALDO > 0 "
cQuery +=" ORDER BY E1_XCOMPET "

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),_cAliasSE1,.T.,.T.)

While (_cAliasSE1)->(!EOF()) 

	AADD(aRet,{.F.,(_cAliasSE1)->E1_NUM,;
					substr((_cAliasSE1)->E1_XCOMPET,1,2)+"/"+substr((_cAliasSE1)->E1_XCOMPET,3,4),;
					STOD((_cAliasSE1)->E1_VENCREA),;
					(_cAliasSE1)->E1_VALOR,"@E 99,999,999,999.99"})

		(_cAliasSE1)->(DBSKIP()) 
end

(_cAliasSE1)->(DbCloseArea())

return(aRet)
