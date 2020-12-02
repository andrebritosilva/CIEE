#Include 'Protheus.ch'

Static lRotinaEXC := .F.

//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CCFGE03
Rotina especifica de visualização dos documentos no Fluig utilizando Auth
@author  	Carlos Henrique
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CCFGE03(cAlias,nRecNo,lHtml,aRecnos, lExc, lIntFlg)
	LOCAL cIdECM		:= ""
	LOCAL cDsTab		:= ""
	//Local cListDoc		:= ""
	//Local aRet			:= NIL
	Local aAdvSize  	:= {}
	LOCAL oDlg			:= NIL
	//LOCAL oListDoc		:= NIL
	//LOCAL oListAux		:= NIL
	LOCAL aButtons		:= {}
	LOCAL aHeader		:= {}
	LOCAL aCols			:= {}
	Local bVisualiza	:= {}
	Local cRet			:= ""
	local aIdEcm        := {}
	Local aArea         := {}
	Local cIdUnico      := ""
	Private aStrChave	:= {}
	Private cCadastro	:= "Gestão de documentos"
	Private oGetD01 	:= NIL
	Private lWfPC       := .F.
	DEFAULT lHtml		:= .F.
	DEFAULT nRecNo		:= 0
	DEFAULT aRecnos     := {nRecNo}
	Default lExc		:= .F.
	DEFAULT lIntFlg		:= .F.

	IF lHtml
		if IsInCallStack("U_C2W01WF") .OR. IsInCallStack("U_C2W01MAN")   // WF Pedido de Compras
			lWfPC := .T.
		endif
		cRet:= C99E03HTM(cAlias,aRecnos)

	ELSE

		If cAlias $ "ZA1|SC1|SC8|SC7|SF1|SE2|CN9"

			cIdUnico := TRIM(FWX2Unico(cAlias))

			If cAlias == "SE2"

				If SE2->E2_EMIS1 > StoD("20180925")

					cIdUnico := StrTran(cIdUnico, "E2_FILIAL", "E2_FILORIG")

				EndIF

			EndIF

			cIdECM:= &(cAlias+"->("+TRIM(cIdUnico)+")")

			aArea := GetArea()

			C99E03TKR(@aIdEcm,cAlias,cIdECM)

			if cAlias == "ZA1"

				If ZA1->ZA1_DATA > StoD("20190206")

					cIdECM := "ZA1" + cIdECM

				endif

			endif

			RestArea(aArea)

		ELSE

			cIdECM:= &(cAlias+"->("+TRIM(FWX2Unico(cAlias))+")")

		EndIf

		cDsTab		:= UPPER(FwSX2Util():GetX2Name(cAlias))
		aStrChave	:= StrTokArr(FwSX2Util():GetSX2data(cAlias, {"X2_DISPLAY"})[1][2],"+")
		aAdvSize  	:= MsAdvSize()

		AADD(aHeader,{"Id","IDDOC","",10,0,"",,"C","","V","","",,"V","",,})
		AADD(aHeader,{"Descrição do documento","DESDOC","",30,0,"",,"C","","V","","",,"V","",,})
		AADD(aHeader,{"Palavras chaves","PALCHA","",20,0,"",,"C","","V","","",,"V","",,})
		AADD(aHeader,{"Nome físico","NOMFIS","",30,0,"",,"C","","V","","",,"V","",,})
		AADD(aHeader,{"Versão","VERDOC","",10,0,"",,"C","","V","","",,"V","",,})
		AADD(aHeader,{"Comentários","COMETA","",30,0,"",,"C","","V","","",,"V","",,})

		If Len(aIdEcm) > 0

			C99E03ATU(aIdEcm,aHeader,@aCols)

		Else

			C99E03ATU(cIdECM,aHeader,@aCols)

		EndIf

		IF lIntFlg
			cRet := C99E03IFL(aHeader,aCols)
		ELSE
			bVisualiza	:= { || C99E03ECM(2,cAlias,cIdECM) }

			AAdd( aButtons, { "WEB" , bVisualiza							, "Visualizar" } )
			AAdd( aButtons, { "WEB" , { || C99E03ECM(3,cAlias,cIdECM, aIdEcm, cIdUnico) }	, "Adicionar" } )
			AAdd( aButtons, { "WEB" , { || C99E03ECM(4,cAlias,cIdECM) }	, "Download" } )
			AAdd( aButtons, { "WEB" , { || C99E03ECM(5,cAlias,cIdECM, aIdEcm) }	, "Remover" } )
			AAdd( aButtons, { "WEB" , { || C99E03ECM(6,cAlias,cIdECM) }	, "Visualizar ECM" } )

			DEFINE MSDIALOG oDlg TITLE cCadastro FROM aAdvSize[7],aAdvSize[1] TO aAdvSize[6],aAdvSize[5] OF oMainWnd PIXEL STYLE DS_SYSMODAL

			EnchoiceBar(oDlg,{|| oDlg:End() },{|| oDlg:End()},,aButtons)

			oLayer:= FWLayer():new()
			oLayer:Init(oDlg,.F.,.T.)
			oLayer:addCollumn("Col01",100,.F.)
			oLayer:addWindow("Col01","Jan01","Gestão de documentos (GED)",30,.F.,.F.,,,)
			oLayer:addWindow("Col01","Jan02","Documentos",70,.F.,.F.,,,)


			// Janela 01
			oPnl01:= oLayer:getWinPanel("Col01","Jan01")
			@05,05 SAY "Código" OF oPnl01 PIXEL
			@15,05 GET oGet VAR cAlias size 30,06 OF oPnl01 PIXEL

			@05,50 SAY "Descrição" OF oPnl01 PIXEL
			@15,50 GET oGet VAR cDsTab size 400,06 OF oPnl01 PIXEL

			@30,05 SAY "Identificação" OF oPnl01 PIXEL
			@40,05 GET oGet VAR cIdECM size 200,06 OF oPnl01 PIXEL

			// Janela 01
			oPnl02:= oLayer:getWinPanel("Col01","Jan02")
			oGetD01:= MsNewGetDados():New(1,1,1,1,0,"AllwaysTrue","AllwaysTrue",,,,999,"AllwaysTrue()",,,oPnl02,aHeader,aCols)
			oGetD01:oBrowse:blDblClick := bVisualiza
			oGetD01:oBrowse:Align:= CONTROL_ALIGN_ALLCLIENT

			If lExc

				RemoveAll()

				u_C99E03STB(.F., .F.)

			Else

				ACTIVATE MSDIALOG oDlg CENTERED ON INIT (oDlg:lEscClose:= .T.)

			EndIF
		EndIF
	ENDIF

Return cRet
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C99E03ATU
Atualiza acols com a lista de documentos
@author  	Carlos Henrique
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
STATIC Function C99E03ATU(xIdECM,aHeader,aCols)
	Local aDadId	:= {}
	LOCAL nCnt		:= 0
	LOCAL nMaxAc	:= 0
	Local nI

	If VALTYPE(xIdECM) == "C"

		aDadId	:= FWGedFindId(xIdECM)

//		aCols := {}

		//Verifica se possui arquivos para exibição
		IF !EMPTY(aDadId)

			FOR nCnt:=1 to LEN(aDadId)
				AADD(aCols,ARRAY(LEN(aHeader)+2))
				nMaxAc:= LEN(aCols)
				aCols[nMaxAc][1]:= aDadId[nCnt][2]
				aCols[nMaxAc][2]:= aDadId[nCnt][3]
				aCols[nMaxAc][3]:= aDadId[nCnt][4]
				aCols[nMaxAc][4]:= aDadId[nCnt][5]
				aCols[nMaxAc][5]:= aDadId[nCnt][6]
				aCols[nMaxAc][6]:= aDadId[nCnt][7]
				aCols[nMaxAc][8]:= .F.
			NEXT nCnt

		/*
		ELSE
			AADD(aCols,ARRAY(LEN(aHeader)+2))
			nMaxAc:= LEN(aCols)
			aCols[nMaxAc][1]:= ""
			aCols[nMaxAc][2]:= ""
			aCols[nMaxAc][3]:= ""
			aCols[nMaxAc][4]:= ""
			aCols[nMaxAc][5]:= ""
			aCols[nMaxAc][6]:= ""
			aCols[nMaxAc][7]:= ""
			aCols[nMaxAc][8]:= .F.
		*/

		ENDIF

	Else

		For nI := 1 to Len(xIdECM)

			aAdd(aDadId, FWGedFindId(xIdECM[nI]))

		Next

		For nI := 1 To Len(aDadId)
			//Verifica se possui arquivos para exibição
			IF !EMPTY(aDadId[nI])
				FOR nCnt:=1 to LEN(aDadId[nI])
					AADD(aCols,ARRAY(LEN(aHeader)+2))
					nMaxAc:= LEN(aCols)
					aCols[nMaxAc][1]:= aDadId[nI][nCnt][2]
					aCols[nMaxAc][2]:= aDadId[nI][nCnt][3]
					aCols[nMaxAc][3]:= aDadId[nI][nCnt][4]
					aCols[nMaxAc][4]:= aDadId[nI][nCnt][5]
					aCols[nMaxAc][5]:= aDadId[nI][nCnt][6]
					aCols[nMaxAc][6]:= aDadId[nI][nCnt][7]
					aCols[nMaxAc][8]:= .F.
				NEXT nCnt
			ENDIF
		Next

		If EMPTY(aCols)
			AADD(aCols,ARRAY(LEN(aHeader)+2))
			nMaxAc:= LEN(aCols)
			aCols[nMaxAc][1]:= ""
			aCols[nMaxAc][2]:= ""
			aCols[nMaxAc][3]:= ""
			aCols[nMaxAc][4]:= ""
			aCols[nMaxAc][5]:= ""
			aCols[nMaxAc][6]:= ""
			aCols[nMaxAc][7]:= ""
			aCols[nMaxAc][8]:= .F.
		EndIf

	EndIf

RETURN
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C99E03ECM
Executa uma ação no fluig de acordo com o parametro
@author  	Carlos Henrique
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
STATIC Function C99E03ECM(nAcao,cAlias,cIdECM, aIdECM, cIdUnico)
	Local nPosIdDoc		:= GDFIELDPOS("IDDOC",oGetD01:AHEADER)
//	Local nPosDescDoc	:= GDFIELDPOS("DESDOC",oGetD01:AHEADER)
//	Local nPosPalCha	:= GDFIELDPOS("PALCHA",oGetD01:AHEADER)
//	Local nPosNomFis	:= GDFIELDPOS("NOMFIS",oGetD01:AHEADER)
//	Local nPosVerDoc	:= GDFIELDPOS("VERDOC",oGetD01:AHEADER)
//	Local nPosCometa	:= GDFIELDPOS("COMETA",oGetD01:AHEADER)
	Local aVarGets		:= {}
	Local lTudook		:= .F.
	Local lLoopUpload	:= .T.
//	Local aCols			:= {}
	Local oDlgGed		:= NIL
	Local cEcmUrl		:= TRIM(SuperGetMv("MV_ECMURL",.F.,""))
	Local cEcmKey		:= TRIM(SuperGetMv("CI_FLGKEY",.F.,"CIEE_KEY"))			// cConsumerKey
	Local cEcmSecret	:= TRIM(SuperGetMv("CI_FLGSEC",.F.,"CIEE_KEY_SECRET"))	// cConsumerSecret
	Local cAccesTok		:= TRIM(SuperGetMv("CI_FLGTOK",.F.,"32d6b21a-f467-4e63-93b3-3f29d70c0dd7"))			//Access token
	Local cTokenSec		:= TRIM(SuperGetMv("CI_FLGTSE",.F.,"7fbdefb3-7704-4bba-b452-96ad0eb948e077b50a0f-8d74-4695-8bbe-9fba44ef245e"))	//Token secret
	Local xRetGed		:= 0
//	Local cErroBlk  	:= ""
//	Local oLastError	:= NIL
	Local cIdTmp        := cIdUnico
	Local cUsuario      := SuperGetMV("CI_USRPERM",.T.,"")
	Local nI			:= 0

	Default aIdECM      := {}

	cEcmUrl:= STRTRAN(cEcmUrl,"/webdesk/","")
	cEcmUrl:= STRTRAN(cEcmUrl,"/WEBDESK/","")

	DO CASE
		//Visualizar documento
		CASE nAcao == 2

		lTudook:= .T.

		IF EMPTY(cEcmUrl)
			lTudook:= .F.
			MSGALERT("Parametro MV_ECMURL não informado!!")
		ENDIF

		IF EMPTY(cEcmKey)
			lTudook:= .F.
			MSGALERT("Parametro CI_FLGKEY não informado!!")
		ENDIF

		IF EMPTY(cEcmSecret)
			lTudook:= .F.
			MSGALERT("Parametro CI_FLGSEC não informado!!")
		ENDIF

		IF EMPTY(cAccesTok)
			lTudook:= .F.
			MSGALERT("Parametro CI_FLGTOK não informado!!")
		ENDIF

		IF EMPTY(cTokenSec)
			lTudook:= .F.
			MSGALERT("Parametro CI_FLGTSE não informado!!")
		ENDIF

		IF EMPTY(oGetD01:ACOLS[oGetD01:NAT][nPosIdDoc])
			lTudook:= .F.
			MSGALERT("Não possui arquivo!")
		Endif

		IF lTudook

			aVarGets:= C99E03URL(cEcmUrl,cEcmKey,cEcmSecret,cAccesTok,cTokenSec,CVALTOCHAR(oGetD01:ACOLS[oGetD01:NAT][nPosIdDoc]))

			IF aVarGets[1]
				ShellExecute("OPEN",aVarGets[2],"","",5)
			ELSE
				MSGALERT(aVarGets[2])
			ENDIF

		ENDIF

		//Adicionar documento
		CASE nAcao == 3

		WHILE lLoopUpload
			aVarGets:= {SPACE(250),SPACE(250),"",""}

			// Monta as palavras chaves
			aEval(aStrChave,{|x|  aVarGets[3]+= TRIM(RetTitle(x))+ ":" + TRIM(&(cAlias+"->("+TRIM(x)+")")) + ","  })

			IF RIGHT(aVarGets[3],1)==","
				aVarGets[3]:= LEFT(aVarGets[3],LEN(aVarGets[3])-1)
			ENDIF

			DEFINE MSDIALOG oDlgGed TITLE cCadastro+" - Upload" FROM 0,0 TO 300,430 OF oDlgGed PIXEL
			@ 05, 05 SAY "Informe o arquivo(*):" SIZE 100,8 PIXEL OF oDlgGed
			@ 12, 05 MSGET aVarGets[1] SIZE 200,10 F3 "DIR" VALID(C99E03VLD(nAcao,1,aVarGets[1]))  PIXEL
			@ 25, 05 SAY   "Descrição(*):" SIZE 100,8 PIXEL OF oDlgGed
			@ 32, 05 MSGET aVarGets[2] SIZE 200,10  PIXEL
			@ 45, 05 SAY   "Palavras chaves:" SIZE 100,8 PIXEL OF oDlgGed
			@ 52, 05 MSGET aVarGets[3] SIZE 200,10  PIXEL
			@ 65, 05 SAY   "Comentários:" SIZE 100,8 PIXEL OF oDlgGed
			@ 72, 05 Get oMemo Var aVarGets[4] Memo Size 200,50 Of oDlgGed Pixel
			oMemo:bRClicked := { || AllwaysTrue() }
			@ 130,110 BUTTON "C&ancelar"   SIZE 36,16 PIXEL ;
			ACTION EVAL({|| lTudook:= .F. , oDlgGed:End() })
			@ 130,160 BUTTON "&Confirma"   SIZE 36,16 PIXEL ;
			ACTION EVAL({|| IIF(lTudook:= C99E03TOK(nAcao,aVarGets),oDlgGed:End(),NIL) })
			ACTIVATE MSDIALOG oDlgGed CENTER

			//Valida se clicou no botão confirmar
			IF lTudook

				nStatus1 := frename(TRIM(aVarGets[1]) , FwNoAccent(TRIM(aVarGets[1])) )

				IF nStatus1 == -1

					MsgStop('Falha ao remover acentos, remova os acentos e letras maiusculas do nome do arquivo!')

				Else

					If Len(aIdECM) > 0 .And. cAlias == "SF1"// .And. SF1->F1_XFLUIG == "1"

						cIdTmp := StrTran(cIdTmp, "F1_SERIE", "F1_XSERFLG")

						Processa({|| xRetGed:= FwGedDocument(FwNoAccent(TRIM(aVarGets[1])),;
						CALIAS,;
						TRIM(&(cAlias+"->("+TRIM(cIdTmp)+")")),;
						TRIM(aVarGets[2]),;
						TRIM(aVarGets[3]),;
						TRIM(aVarGets[4]))  },"Realizando upload do arquivo, aguarde...")

/*					elseif cAlias == "ZA1"

						Processa({|| xRetGed:= FwGedDocument(FwNoAccent(TRIM(aVarGets[1])),;
						CALIAS,;
						TRIM("ZA1"+cIdECM),;
						TRIM(aVarGets[2]),;
						TRIM(aVarGets[3]),;
						TRIM(aVarGets[4]))  },"Realizando upload do arquivo, aguarde...")*/

					Else

						Processa({|| xRetGed:= FwGedDocument(FwNoAccent(TRIM(aVarGets[1])),;
						CALIAS,;
						TRIM(cIdECM),;
						TRIM(aVarGets[2]),;
						TRIM(aVarGets[3]),;
						TRIM(aVarGets[4]))  },"Realizando upload do arquivo, aguarde...")

					EndIF

					IF xRetGed >= 0
						oGetD01:ACOLS:= {}

						If Len(aIdECM) > 0

							For nI := 1 To Len(aIdECM)

								C99E03ATU(aIdECM[nI],oGetD01:AHEADER,@oGetD01:ACOLS)

							Next

						Else

							C99E03ATU(cIdECM,oGetD01:AHEADER,@oGetD01:ACOLS)

						EndIF
						oGetD01:oBrowse:Refresh()
						MSGINFO("Documento atualizado.")
					ELSE
						MSGALERT("Não foi possivel adiconar o arquivo!")
					ENDIF
				Endif
			Else
				lLoopUpload:=.F.
			ENDIF
		END

		//Download do documento
		CASE nAcao == 4

		IF EMPTY(oGetD01:ACOLS[oGetD01:NAT][nPosIdDoc])
			MSGALERT("Não possui arquivo!")
		ELSE
			aVarGets	 	:= {""}
			aVarGets[1]	:= cGetfile(,,,, .T., nOR( GETF_LOCALHARD, GETF_RETDIRECTORY ),.T., .T. )

			IF EXISTDIR(aVarGets[1])
				Processa({|| xRetGed:= FwGedDownload(aVarGets[1],;
				oGetD01:ACOLS[oGetD01:NAT][1],;
				oGetD01:ACOLS[oGetD01:NAT][5])  },"Realizando Download do arquivo, aguarde...")

				IF xRetGed >= 0
					MSGINFO("Arquivo baixado com sucesso!!")
				ELSE
					MSGALERT("Não foi possivel baixar o arquivo!!")
				ENDIF
			ELSE
				MSGALERT("Diretório não localizado: " + aVarGets[1])
			ENDIF
		ENDIF

		//Remover documento
		CASE nAcao == 5
		   aUsuario := __cUserId

		If (cAlias == "SF1") .And. !(RetCodUsr() $ cUsuario)

			Alert("Você não possui permissão para excluir este documento!")

		Else

			IF EMPTY(oGetD01:ACOLS[oGetD01:NAT][nPosIdDoc])
				MSGALERT("Não possui arquivo!")
			ELSE
				IF MSGYESNO("Confirma a exclusão do documento  ? " +CRLF + oGetD01:ACOLS[oGetD01:NAT][4])

					Processa({|| xRetGed:= FWGedDelId(oGetD01:ACOLS[oGetD01:NAT][nPosIdDoc])  },"Realizando exclusão do arquivo, aguarde...")

					IF xRetGed
//						oGetD01:ACOLS:= {}
//						C99E03ATU(cIdECM,oGetD01:aHeader,@oGetD01:ACOLS)
//						oGetD01:oBrowse:Refresh()
//						MSGINFO("Arquivo excluido com sucesso!!")

						oGetD01:ACOLS:= {}

						If Len(aIdECM) > 0

							For nI := 1 To Len(aIdECM)

								C99E03ATU(aIdECM[nI],oGetD01:AHEADER,@oGetD01:ACOLS)

							Next

						Else

							C99E03ATU(cIdECM,oGetD01:AHEADER,@oGetD01:ACOLS)

						EndIF
						oGetD01:oBrowse:Refresh()
						MSGINFO("Arquivo excluido com sucesso!!")
					ELSE
						If U_CancArq(cValToChar(oGetD01:ACOLS[oGetD01:NAT][nPosIdDoc]))

							oGetD01:ACOLS:= {}
							C99E03ATU(cIdECM,oGetD01:aHeader,@oGetD01:ACOLS)
							oGetD01:oBrowse:Refresh()
							MSGINFO("Arquivo excluido com sucesso!!")

						Else

							MSGALERT("O arquivo não pode ser excluido!!")

						EndIf
					ENDIF
				ENDIF
			ENDIF

		EndIF

		//Visualizador ECM - Com login
		CASE nAcao == 6

		IF EMPTY(oGetD01:ACOLS[oGetD01:NAT][nPosIdDoc])
			MSGALERT("Não possui arquivo!")
		ELSE
			aVarGets:= {"",NIL}
			aVarGets[1] := cEcmUrl + "/portal/p/"+alltrim(GetMv("MV_ECMEMP",.F.,""))+"/ecmnavigation?app_ecm_navigation_doc="+ CVALTOCHAR(oGetD01:ACOLS[oGetD01:NAT][nPosIdDoc])

			IF !EMPTY(aVarGets[1])
				ShellExecute("OPEN",aVarGets[1],"","",5)
			ENDIF
		ENDIF

	ENDCASE

RETURN
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C99E03TOK
Rotina de validação tudo OK
@author  	Carlos Henrique
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
STATIC Function C99E03TOK(nAcao,aGets)
	Local lRet:= .T.

	DO CASE
		//Adicionar documento
		CASE nAcao == 3

		IF !FILE(aGets[1])
			MSGALERT("Arquivo não localizado: " + aGets[1])
			lRet:= .F.
		ENDIF

		IF EMPTY(aGets[2])
			MSGALERT("Campo descrição é obrigatório!")
			lRet:= .F.
		ENDIF

	ENDCASE

RETURN lRet
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C99E03VLD
Rotina de validação
@author  	Carlos Henrique
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
STATIC Function C99E03VLD(nAcao,nIdGet,cValorGet)
	Local lRet:= .T.

	DO CASE
		//Adicionar documento
		CASE nAcao == 3

		IF nIdGet == 1 .and. !EMPTY(cValorGet)
			IF !FILE(cValorGet)
				MSGALERT("Arquivo não localizado: " + cValorGet)
				lRet:= .F.
			ENDIF
		ENDIF

	ENDCASE

RETURN lRet
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C99E03HTM
Monta html com a lista de documentos
@author  	Carlos Henrique
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
STATIC Function C99E03HTM(cAlias,aRecnos)
	Local cRet		:= ""
	Local aDadId	:= {}
	LOCAL nCnt		:= 0
	LOCAL nXRec		:= 0
//	LOCAL nMaxAc	:= 0
	Local aVarGets	:= {}
	Local aIdECM	:= {}
	Local cEcmUrl	:= TRIM(SuperGetMv("MV_ECMURL",.F.,""))
	Local cEcmKey	:= TRIM(SuperGetMv("CI_FLGKEY",.F.,"CIEE_KEY"))			// cConsumerKey
	Local cEcmSecret:= TRIM(SuperGetMv("CI_FLGSEC",.F.,"CIEE_KEY_SECRET"))	// cConsumerSecret
	Local cAccesTok	:= TRIM(SuperGetMv("CI_FLGTOK",.F.,"32d6b21a-f467-4e63-93b3-3f29d70c0dd7"))			//Access token
	Local cTokenSec	:= TRIM(SuperGetMv("CI_FLGTSE",.F.,"7fbdefb3-7704-4bba-b452-96ad0eb948e077b50a0f-8d74-4695-8bbe-9fba44ef245e"))	//Token secret
	Local nI
	Local nAchouItem := 0
	Local cIdUnico	 := ""

	cEcmUrl:= STRTRAN(cEcmUrl,"/webdesk/","")
	cEcmUrl:= STRTRAN(cEcmUrl,"/WEBDESK/","")

	cRet+= "<h3 style='-moz-box-sizing: border-box;box-sizing: border-box;orphans: 3;widows: 3;page-break-after: avoid;font-family: inherit;font-weight: 500;line-height: 1.1;color: inherit;margin-top: 20px;margin-bottom: 10px;font-size: 18px;'><b style='-moz-box-sizing: border-box;box-sizing: border-box;font-weight: 700;'>Documentos Relacionados</b></h3>"+CRLF
	cRet+= "<table style='-moz-box-sizing: border-box;box-sizing: border-box;border-collapse: collapse!important;border-spacing: 0;background-color: transparent;width: 100%;max-width: 100%;margin-bottom: 20px;'>"+CRLF
	cRet+= "<tbody style='-moz-box-sizing: border-box;box-sizing: border-box;' >"+CRLF
	cRet+= "   <tr style='-moz-box-sizing: border-box;box-sizing: border-box;page-break-inside: avoid;'>"+CRLF
	cRet+= "	  <th style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;text-align: left;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border-top: 1px solid #ddd;'>Id</th>"+CRLF
	cRet+= "	  <th style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;text-align: left;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border-top: 1px solid #ddd;'>Descrição do documento</th>"+CRLF
	cRet+= "	  <th style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;text-align: left;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border-top: 1px solid #ddd;'>Nome físico</th>"+CRLF
	if IsInCallStack("U_CCOME27")  // Cartão de visita
		cRet+= "	  <th style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;text-align: left;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border-top: 1px solid #ddd;'>Quantidade</th>"+CRLF
//	else
//		cRet+= "	  <th style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;text-align: left;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border-top: 1px solid #ddd;'>Versão</th>"+CRLF
	endif
	cRet+= "	  <th style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;text-align: left;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border-top: 1px solid #ddd;'>Comentários</th>"+CRLF
	cRet+= "	  <th style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;text-align: left;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border-top: 1px solid #ddd;'>Anexo</th>"+CRLF
	cRet+= "   </tr>"+CRLF
	cRet+= "<tbody>"+CRLF

	//DBSELECTAREA("SX2")
	//SX2->(DBSEEK(cAlias))
	IF EMPTY(FwSX2Util():GetSX2data(cAlias, {"X2_DISPLAY"})[1][2])
		cRet+= "   <tr bgcolor='#A4A4A4' style='-moz-box-sizing: border-box;box-sizing: border-box;page-break-inside: avoid;'>"+CRLF
		cRet+= "      <td colspan='7 align='center' ><b>Campo X2_DISPLAY não informado para tabela: '+ cAlias +'</b></td>"+CRLF
		cRet+= "   </tr>"+CRLF
	ELSE
		FOR nXRec:=1 TO LEN(aRecnos)
			&(cAlias+"->(DBGOTO("+ CVALTOCHAR(aRecnos[nXRec]) +"))")

			IF &(cAlias+"->(!EOF())")

				cIdUnico := TRIM(FWX2Unico(cAlias))

				If cAlias == "SE2"

					If SE2->E2_EMIS1 > StoD("20180925")

						cIdUnico := StrTran(cIdUnico, "E2_FILIAL", "E2_FILORIG")

					EndIF

				EndIF

				C99E03TKR(@aIdEcm,cAlias,&(cAlias+"->("+cIdUnico+")"))

				If Len(aIdEcm) > 0

					For nI := 1 To Len(aIdEcm)

						aDadId	:= FWGedFindId(aIdEcm[nI])

						//Verifica se possui arquivos para exibição
						IF !EMPTY(aDadId)
							FOR nCnt:=1 to LEN(aDadId)
								nAchouItem++
								cRet+= "   <tr style='-moz-box-sizing: border-box;box-sizing: border-box;page-break-inside: avoid;'>"+CRLF
								cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ CVALTOCHAR(aDadId[nCnt][2]) +"</td>"+CRLF
								cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ aDadId[nCnt][3] +"</td>"+CRLF
								cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ aDadId[nCnt][5] +"</td>"+CRLF
								if IsInCallStack("U_CCOME27")  // Cartão de visita

									if nI > 1

										while nI < len(aIdEcm)

											if "ZA1" $ aIdEcm[nI]

												exit

											endif

											nI++

										enddo
										DBSELECTAREA("ZA1")
										ZA1->(DBSETORDER(1))
										if ZA1->(DbSeek(strtran(aIdEcm[nI], "ZA1", "")))
											cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ CVALTOCHAR(ZA1->ZA1_QUANT) +"</td>"+CRLF
										else
											cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'></td>"+CRLF
										endif

									else

										DBSELECTAREA("ZA1")
										ZA1->(DBSETORDER(1))
										if ZA1->(DbSeek(aIdEcm[nI]))
											cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ CVALTOCHAR(ZA1->ZA1_QUANT) +"</td>"+CRLF
										else
											cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'></td>"+CRLF
										endif

									endif
								endif
								cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ aDadId[nCnt][7] +"</td>"+CRLF

								// Monta URL do documento
								aVarGets:= C99E03URL(cEcmUrl,cEcmKey,cEcmSecret,cAccesTok,cTokenSec,CVALTOCHAR(aDadId[nCnt][2]))

								SLEEP(200) // Segura um tempo no processamento

								IF aVarGets[1]
									cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'><a href='"+ aVarGets[2] +"' target='_blank'>Link</a></td>"+CRLF
								ELSE
									cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ aVarGets[2] +"</td>"+CRLF
								ENDIF

								sleep(1500)

								cRet+= "   </tr>"+CRLF
							NEXT nCnt
						ENDIF

					Next

					IF nAchouItem == 0
						cRet+= "   <tr bgcolor='#A4A4A4' style='-moz-box-sizing: border-box;box-sizing: border-box;page-break-inside: avoid;'>"+CRLF
						cRet+= "      <td colspan='7 align='center'><b>Não existe documentos vinculado ao processo.</b></td>"+CRLF
						cRet+= "   </tr>"+CRLF
					ENDIF

				Else

					cIdUnico := TRIM(FWX2Unico(cAlias))

					If cAlias == "SE2"

						If SE2->E2_EMIS1 > StoD("20180925")

							cIdUnico := StrTran(cIdUnico, "E2_FILIAL", "E2_FILORIG")

						EndIF

					EndIF

					cIdECM	:= &(cAlias+"->("+cIdUnico+")")
					aDadId	:= FWGedFindId(cIdECM)

					//Verifica se possui arquivos para exibição
					IF !EMPTY(aDadId)
						FOR nCnt:=1 to LEN(aDadId)

							cRet+= "   <tr style='-moz-box-sizing: border-box;box-sizing: border-box;page-break-inside: avoid;'>"+CRLF
							cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ CVALTOCHAR(aDadId[nCnt][2]) +"</td>"+CRLF
							cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ aDadId[nCnt][3] +"</td>"+CRLF
							cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ aDadId[nCnt][5] +"</td>"+CRLF
							if IsInCallStack("U_CCOME27")  // Cartão de visita
								cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'></td>"+CRLF
//							else
//								cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ CVALTOCHAR(aDadId[nCnt][6]) +"</td>"+CRLF
							endif
							cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ aDadId[nCnt][7] +"</td>"+CRLF

							// Monta URL do documento
							aVarGets:= C99E03URL(cEcmUrl,cEcmKey,cEcmSecret,cAccesTok,cTokenSec,CVALTOCHAR(aDadId[nCnt][2]))
							SLEEP(200) // Segura um tempo no processamento
							IF aVarGets[1]
								cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'><a href='"+ aVarGets[2] +"' target='_blank'>Link</a></td>"+CRLF
							ELSE
								cRet+= "	  <td style='-moz-box-sizing: border-box;box-sizing: border-box;padding: 8px;font-size: 14px;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #595959;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #fff!important;border: 0;line-height: 1.42857143;vertical-align: top;border: 1px solid #ddd;'>"+ aVarGets[2] +"</td>"+CRLF
							ENDIF
							sleep(1500)
							cRet+= "   </tr>"+CRLF
						NEXT nCnt
					ELSE
						cRet+= "   <tr bgcolor='#A4A4A4' style='-moz-box-sizing: border-box;box-sizing: border-box;page-break-inside: avoid;'>"+CRLF
						cRet+= "      <td colspan='7 align='center'><b>Não existe documentos vinculado ao processo.</b></td>"+CRLF
						cRet+= "   </tr>"+CRLF
					ENDIF

				EndIf

			ELSE
				cRet+= "   <tr bgcolor='#A4A4A4' style='-moz-box-sizing: border-box;box-sizing: border-box;page-break-inside: avoid;'>"+CRLF
				cRet+= "      <td colspan='7 align='center'><b>Registro não localizado.</b></td>"+CRLF
				cRet+= "   </tr>"+CRLF
			ENDIF
		NEXT nXRec
	ENDIF

	cRet+= "</tbody>"+CRLF
	cRet+= "</table>"+CRLF

RETURN cRet
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C99E03URL
Monta url de acesso via OUTH no Fluig
@author  	Carlos Henrique
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
STATIC Function C99E03URL(cEcmUrl,cEcmKey,cEcmSecret,cAccesTok,cTokenSec,cIDDoc)
	Local aVarGets	:= {}
	Local cErroBlk  := ""
	Local oLastError:= NIL
	Local oCltFluig	:= NIL
	Local aRet		:= {.T.,""}

	Private __cInternet := Nil

	oLastError:= ErrorBlock({|e| cErroBlk := + e:Description + e:ErrorStack , BREAK(e) })

	BEGIN SEQUENCE
		// Monta o client
		// FWoAuth1Fluig():New( cConsumerKey, cConsumerSecret, cHost , cCallBack)
		oCltFluig := FWoAuth1Fluig():New(cEcmKey,cEcmSecret,cEcmUrl,cEcmUrl)

		//Seta os tokens para consumir o serviço
		oCltFluig:SetToken(cAccesTok) 			//Access token
		oCltFluig:SetSecretToken(cTokenSec) 	//Token secret

		// Consome um serviço do Fluig
		// Method Get(cURL, cQuery, cBody, aHeadOut, aHeadRet, lUTF8)
		aVarGets	:= {"",NIL}
		aVarGets[1]	:= oCltFluig:Get(oCltFluig:cHost + "/api/public/ecm/document/activedocument/"+ cIDDoc )

		IF aVarGets[1] != NIL
			If FWJsonDeserialize(aVarGets[1],@aVarGets[2])
				IF VALTYPE(aVarGets[2]:CONTENT) == "O"
					aRet[2]:= aVarGets[2]:CONTENT:FILEURL
				ELSEIF UPPER(aVarGets[2]:CONTENT)!= "ERROR"
					aRet[2]:= aVarGets[2]:CONTENT:FILEURL
				ELSE
					aRet[1]:= .F.
					aRet[2]:= "Não foi possível realizar a visualização do arquivo: "
				ENDIF
			Else
				aRet[1]:= .F.
				aRet[2]:= "Não foi possível realizar a visualização do arquivo: "

			ENDIF
		ELSE

			aVarGets[1]	:= oCltFluig:Get(oCltFluig:cHost + "/api/public/ecm/document/activedocument/"+ cIDDoc )

			IF aVarGets[1] != NIL
				If FWJsonDeserialize(aVarGets[1],@aVarGets[2])
					IF VALTYPE(aVarGets[2]:CONTENT) == "O"
						aRet[2]:= aVarGets[2]:CONTENT:FILEURL
					ELSEIF UPPER(aVarGets[2]:CONTENT)!= "ERROR"
						aRet[2]:= aVarGets[2]:CONTENT:FILEURL
					ELSE
						aRet[1]:= .F.
						aRet[2]:= "Não foi possível realizar a visualização do arquivo: "
					ENDIF
				ENDIF
			ELSE
				MSGALERT("Não foi possível realizar a autenticação no Fluig!!")
			EndIf
		ENDIF

	END SEQUENCE

	ErrorBlock(oLastError)

	IF !EMPTY(cErroBlk)
		aRet[1]:= .F.
		aRet[2]:= "Não foi possível realizar a conexão com Fluig :"+ cErroBlk
	ENDIF

Return aRet
/*/{Protheus.doc} C99E03TKR
Montar traker da tabela posicionada
@author carlos.henrique
@since 14/02/2018
@version undefined
@param cAlias, characters, descricao
@type function
/*/
static Function C99E03TKR(aRet,cAlias,cChave)
Local aArea	:= (cAlias)->(Getarea())
Local cX2Key:= ""
Local cNumSC:= ""
Local aSCItem:= {}
Local cNumCot:= ""
Local cNumPed:= ""

DO CASE
	CASE cAlias == "SE2"

		AADD(aRet, cChave )

		IF "MATA"$SE2->E2_ORIGEM
			DBSELECTAREA("SF1")
			SF1->(dbSetOrder(1))
			IF SF1->(dbSeek(SE2->(E2_FILORIG+E2_NUM+E2_PREFIXO+E2_FORNECE+E2_LOJA)))
				C99E03TKR(@aRet,"SF1",&("SF1->("+TRIM( C99E03PKT("SF1") )+")"))
			ENDIF

		//Para titulos de adiantamento verificar anexos vinculados ao pedido de compra
		//Observação ==> Apos a inclusão da nota fiscal de entrada a leitura para a ser pela tabela SF1
		ELSEIF SE2->E2_TIPO=="PA "
			DBSELECTAREA("FIE")
			FIE->(DBSETORDER(3)) //FIE_FILIAL+FIE_CART+FIE_FORNEC+FIE_LOJA+FIE_PREFIX+FIE_NUM+FIE_PARCEL+FIE_TIPO+FIE_PEDIDO
			IF FIE->(DBSEEK(XFILIAL("FIE")+"P"+SE2->(E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO)))
				DBSELECTAREA("SC7")
				SC7->(DbGotop())
				SC7->(DbSetOrder(1))
				If SC7->(DbSeek(xFilial("SC7")+FIE->FIE_PEDIDO))
					C99E03TKR(@aRet,"SC7",&("SC7->("+TRIM( C99E03PKT("SC7") )+")"))
				Endif
			ENDIF
		ENDIF

	CASE cAlias == "SF1"

		cUnico := TRIM(FWX2Unico(cAlias))
		cUnico := StrTran(cUnico, "F1_SERIE", "F1_XSERFLG")
		AADD(aRet, &(cAlias+"->("+TRIM(cUnico)+")") )

		//Ajusta chave para pesquisa na tabela SD1
		cChave:= SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)
		cNumPed:= ""

		//Verifica se possui pedido de compra
		SD1->(DbGotop())
		SD1->(DbSetOrder(1))//D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
		SD1->(DbSeek(cChave))
		While SD1->(!EOF()) .and. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == cChave
			IF !EMPTY(SD1->D1_PEDIDO) .and. SD1->D1_PEDIDO!=cNumPed
				cNumPed:= SD1->D1_PEDIDO
				SC7->(DbGotop())
				SC7->(DbSetOrder(1))
				If SC7->(DbSeek(xFilial("SC7")+SD1->D1_PEDIDO))
					C99E03TKR(@aRet,"SC7",&("SC7->("+TRIM( C99E03PKT("SC7") )+")"))
				Endif
			ENDIF
		SD1->(DBSKIP())
		END

	CASE cAlias == "SC7"

		cX2Key:= C99E03PKT("SC7")
		cChave:= SC7->(C7_FILIAL+C7_NUM)
		cNumSC:= ""
		cNumCot:=""

		DBSELECTAREA("SC7")
		DBSETORDER(1)
		SC7->(DBSEEK(cChave))
		WHILE SC7->(!EOF()) .AND. SC7->(C7_FILIAL+C7_NUM)==cChave

			AADD(aRet,&("SC7->("+TRIM( cX2Key )+")"))

			if !lWfPC  // Se for WF Pedido de Compra pegar traker somente do SC7.
				IF !EMPTY(SC7->C7_NUMCOT) .AND. SC7->C7_NUMCOT!=cNumCot
					cNumCot:= SC7->C7_NUMCOT
					DBSELECTAREA("SC8")
					DBSETORDER(1)
					IF SC8->(DBSEEK(XFILIAL("SC8")+SC7->C7_NUMCOT))
						C99E03TKR(@aRet,"SC8",&("SC8->("+TRIM( C99E03PKT("SC8") )+")"))
					ENDIF
				ENDIF

				//Pedido gerado por SC sem cotação
				IF !EMPTY(SC7->C7_NUMSC) .AND. EMPTY(SC7->C7_NUMCOT) .AND. SC7->C7_NUMSC != cNumSC
					cNumSC:= SC7->C7_NUMSC
					DBSELECTAREA("SC1")
					DBSETORDER(1)
					IF SC1->(DBSEEK(XFILIAL("SC1")+SC7->(C7_NUMSC+C7_ITEMSC)))
						C99E03TKR(@aRet,"SC1",&("SC1->("+TRIM( C99E03PKT("SC1") )+")"))
					ENDIF
				ENDIF
			endif

		SC7->(DBSKIP())
		END

	CASE cAlias == "SC8"

		cX2Key:= C99E03PKT("SC8")
		cChave:= SC8->(C8_FILIAL+C8_NUM)
		aSCItem:= {}

		DBSELECTAREA("SC8")
		DBSETORDER(1)
		SC8->(DBSEEK(cChave))
		WHILE SC8->(!EOF()) .AND. SC8->(C8_FILIAL+C8_NUM)==cChave

			AADD(aRet,&("SC8->("+TRIM( cX2Key )+")"))

			IF ASCAN(aSCItem,{|x| x==SC8->C8_NUMSC+SC8->C8_ITEMSC }) == 0
				AADD(aSCItem,SC8->C8_NUMSC+SC8->C8_ITEMSC)
				DBSELECTAREA("SC1")
				DBSETORDER(1)
				IF SC1->(DBSEEK(XFILIAL('SC1')+SC8->C8_NUMSC+SC8->C8_ITEMSC))
					C99E03TKR(@aRet,"SC1",&("SC1->("+TRIM( C99E03PKT("SC1") )+")"))
				ENDIF
			ENDIF

			SC8->(DBSKIP())
		END

	CASE cAlias == "SC1"

//		cX2Key:= C99E03PKT("SC1")
//		cChave:= SC1->(C1_FILIAL+C1_NUM)
		if Empty(SC1->C1_FISCORI) .and. Empty(SC1->C1_SCORI) .and. Empty(SC1->C1_ITSCORI)
			cChave:= SC1->(C1_FILIAL+C1_NUM)
		else
			cChave:= SC1->(C1_FISCORI+C1_SCORI)
		endif
		cNumSC:= ""

		DBSELECTAREA("SC1")
		DBSETORDER(1)
		SC1->(DBSEEK(cChave))
		WHILE SC1->(!EOF()) .AND. SC1->(C1_FILIAL+C1_NUM)==cChave

			if Empty(SC1->C1_FISCORI) .and. Empty(SC1->C1_SCORI) .and. Empty(SC1->C1_ITSCORI)
				cX2Key:= C99E03PKT("SC1")
			else
				cX2Key:= "C1_FISCORI+C1_SCORI+C1_ITSCORI+SPACE(03)"
			endif

			IF ASCAN(aRet,{|x| x==&("SC1->("+TRIM( cX2Key )+")") }) == 0

				AADD(aRet,&("SC1->("+TRIM( cX2Key )+")"))

				IF !EMPTY(SC1->C1_XNUCIEE) .and. SC1->C1_XNUCIEE!=cNumSC
					cNumSC:= SC1->C1_XNUCIEE
					DBSELECTAREA("ZA1")
					DBSETORDER(1)
//					IF ZA1->(DBSEEK(xfilial("ZA1")+SC1->C1_XNUCIEE))
					IF ZA1->(DBSEEK(SC1->C1_FILIAL+SC1->C1_XNUCIEE))

						C99E03TKR(@aRet,"ZA1",&("ZA1->("+TRIM( C99E03PKT("ZA1") )+")"))

					Endif
				Endif

			endif

		SC1->(DBSKIP())
		END

	CASE cAlias == "ZA1"

		cX2Key:= C99E03PKT("ZA1")
		cChave:= ZA1->(ZA1_FILIAL+ZA1_COD)

		DBSELECTAREA("ZA1")
		DBSETORDER(1)
		ZA1->(DBSEEK(cChave))

		WHILE ZA1->(!EOF()) .AND. ZA1->(ZA1_FILIAL+ZA1_COD)==cChave
			If ZA1->ZA1_DATA > StoD("20190206")
				AADD(aRet,"ZA1" + &("ZA1->("+TRIM( cX2Key )+")"))
			else
				AADD(aRet,&("ZA1->("+TRIM( cX2Key )+")"))
			endif

			ZA1->(DBSKIP())
		END

	CASE cAlias == "ZCC"

		cX2Key:= C99E03PKT("ZCC")
		cChave:= ZCC->(ZCC_FILIAL+ZCC_IDREP)

		DBSELECTAREA("ZCC")
		DBSETORDER(1)
		ZCC->(DBSEEK(cChave))

		WHILE ZCC->(!EOF()) .AND. ZCC->(ZCC_FILIAL+ZCC_IDREP)==cChave
			AADD(aRet,&("ZCC->("+TRIM( cX2Key )+")"))
			ZCC->(DBSKIP())
		END

	CASE cAlias == "CN9"

		cX2Key:= C99E03PKT("CNK")
		cChave:= CN9->(CN9_FILIAL+CN9_NUMERO)

		DBSELECTAREA("CNK")
		DBSETORDER(3)
		CNK->(DBSEEK(cChave))
		WHILE CNK->(!EOF()) .AND. CNK->(CNK_FILIAL+CNK_CONTRA)==cChave
			AADD(aRet,&("CNK->("+TRIM( cX2Key )+")"))
		CNK->(DBSKIP())
		END

ENDCASE

RestArea(aArea)
RETURN
/*/{Protheus.doc} C99E03PKT
Retorna o x2_unico de acordo com a tabela
@author carlos.henrique
@since 05/02/2018
@version undefined
@param cAlias, characters, descricao
@type function
/*/
STATIC Function C99E03PKT(cAlias)
Local cX2Unico:=""

DBSELECTAREA("SX2")
IF SX2->(DBSEEK(cAlias))
	cX2Unico:= TRIM(FWX2Unico(cAlias))
ENDIF

RETURN cX2Unico

USER Function C99E03STB(lSet, lConsulta)

	If !lConsulta
		lRotinaEXC := lSet
	EndIF

RETURN lRotinaEXC

User Function CancArq(cIdArquivo)
	Local cEcmUrl		:= TRIM(SuperGetMv("MV_ECMURL",.F.,""))
	Local cEcmKey		:= TRIM(SuperGetMv("CI_FLGKEY",.F.,"CIEE_KEY"))			// cConsumerKey
	Local cEcmSecret	:= TRIM(SuperGetMv("CI_FLGSEC",.F.,"CIEE_KEY_SECRET"))	// cConsumerSecret
	Local cAccesTok		:= TRIM(SuperGetMv("CI_FLGTOK",.F.,"32d6b21a-f467-4e63-93b3-3f29d70c0dd7"))			//Access token
	Local cTokenSec		:= TRIM(SuperGetMv("CI_FLGTSE",.F.,"7fbdefb3-7704-4bba-b452-96ad0eb948e077b50a0f-8d74-4695-8bbe-9fba44ef245e"))	//Token secret

	Local oCltFluig     := FWoAuth1Fluig():New(cEcmKey,cEcmSecret,cEcmUrl,cEcmUrl)

	Local cJson 		:= ""
	Local cRet          := ""
	Local oJson         := Nil

	Local lRet          := .F.

	If !Empty(cIdArquivo)

		cEcmUrl:= STRTRAN(cEcmUrl,"/webdesk/","")
		cEcmUrl:= STRTRAN(cEcmUrl,"/WEBDESK/","")

		cJson += "{" + CRLF
		cJson += '"datasetId" : "ds_update_arquivo",' + CRLF
		cJson += '"filterFields" : ["field1", "field2"],' + CRLF
		cJson += '"resultFields" : ["' + cIdArquivo + '", "value2"],' + CRLF
		cJson += '"limit" : "50"' + CRLF
		cJson += "}" + CRLF

		oCltFluig:SetToken(cAccesTok) 			//Access token
		oCltFluig:SetSecretToken(cTokenSec) 	//Token secret

		cRet := oCltFluig:Post(cEcmUrl + "/api/public/ecm/dataset/search",,cJson )

		If FWJsonDeserialize(cRet, @oJson)

			If VALTYPE(oJson:CONTENT[1]:CDRESULT) == "C"

				If oJson:CONTENT[1]:CDRESULT == "1"

					lRet := .T.

				Else

					U_uCONOUT("CCFGE03 =========> " + oJson:CONTENT[1]:CDRESULT)

				EndIf

			EndIf

		Else

			U_uCONOUT("CCFGE03 =========> Falha no retorno Json")

		EndIf

	Else

		U_uCONOUT("CCFGE03 =========> Id do arquivo vazio")

	endIf

return lRet

Static Function RemoveAll()
	Local nI
	Local nPosIdDoc		:= GDFIELDPOS("IDDOC",oGetD01:AHEADER)

	IF EMPTY(oGetD01:ACOLS[1][1])
		MSGALERT("Não possui arquivo!")
	ELSE

		For nI := 1 to Len(oGetD01:ACOLS)

			xRetGed:= FWGedDelId(oGetD01:ACOLS[nI][nPosIdDoc])

			IF !xRetGed

//				Sleep(1000)
				Sleep(1500)

				If !U_CancArq(cValToChar(oGetD01:ACOLS[nI][nPosIdDoc]))

					MSGALERT("Falha ao excluir arquivos, contate o administrador passando o código EXC001!")

				EndIf
			ENDIF

		Next

	ENDIF

Return
/*/{Protheus.doc} C99E03IFL
Monta string com id dos documentos relacionados
@author carlos.henrique
@since 24/05/2019
@version undefined
@param aHeader, array, descricao
@param aCols, array, descricao
@type function
/*/
STATIC FUNCTION C99E03IFL(aHeader,aCols)
Local nIdDoc:= ASCAN(aHeader,{|x| TRIM(UPPER(x[2]))=="IDDOC" })
Local cRet	:= ""

IF nIdDoc > 0
	aEval(aCols,{|x| cRet+= TRIM(CVALTOCHAR(x[nIdDoc]))+"-" })
	IF RIGHT(cRet,1) == "-"
		cRet:= LEFT(cRet,LEN(cRet)-1)
	ENDIF
ENDIF

Return cRet