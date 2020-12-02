#Include 'Protheus.ch'
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MS520DEL
Ponto de entrada localizado na função MaDelNfs antes da exclusão do registro da tabela SF2
@author  	Carlos Henrique
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function MS520DEL()
Local aArea	:= u_GETALLAREA()
Local cNota   := SF2->F2_DOC
Local cCliente:= SF2->F2_CLIENTE
Local cLoja   := SF2->F2_LOJA
Local cCodMot := SF3->F3_CODMOT
Local cDesMot := SF3->F3_XDESMOT
Local cDesCod := ""
Local cTabCodM:= AllTrim(GetNewPar("CI_TABCMOT",""))
Local oDlg		:= nil
Local lCodMot	:= .F.
Local lConfirm:= .F.
Local lRet	  	:= .F.

If isincallstack("U_CEAIA07") .AND. !ISINCALLSTACK("U_C05A01CM")

	RECLOCK("SF3",.F.)
	SF3->F3_CODMOT	:= IIF(SF3->F3_FILIAL=="0003","01","")
	SF3->F3_XDESMOT := ZC5->ZC5_DESMOT
	
	IF CFILANT == "0003"
		SF3->F3_DESCRET	:= "NF CANCELADA"
	ENDIF
		
	SF3->(MSUnlock())

ELSE
	//Verifica se possui tabela de código de motivos
	IF !EMPTY(cTabCodM)
		DBSELECTAREA("SX5")
		SX5->(dbSelectArea(1))  // X5_FILIAL + X5_TABELA + X5_CHAVE
		If SX5->(dbSeek(xFilial("SX5")+cTabCodM))
			lCodMot	:= .T.
		ENDIF
	ENDIF
	
	//Realiza loop se não respeitar a regra
	WHILE !lRet
		DEFINE MSDIALOG oDlg TITLE "Motivo de Cancelamento" FROM 0,0 TO 200,600 OF oDlg PIXEL
		@ 06,06 TO 90,300 LABEL "Preencher as Informações:" OF oDlg PIXEL
		@ 15, 15 SAY   "Nota:"+cNota SIZE 45,8 PIXEL OF oDlg
		@ 15, 80 SAY   "Cliente: "+cCliente+cLoja SIZE 45,8 PIXEL OF oDlg
		
		IF lCodMot
			@ 22, 15 SAY   "Código do Motivo de cancelamento:" SIZE 100,8 PIXEL OF oDlg
			@ 30, 15 MSGET cCodMot SIZE 20,10 F3 cTabCodM PICTURE PesqPict("SF3","F3_CODMOT") VALID(VALCODMOT(cTabCodM,cCodMot,@cDesCod))  PIXEL
			@ 30, 40 MSGET cDesCod SIZE 100,10 when .F.  PIXEL
			@ 45, 15 SAY   "Descrição do Motivo de cancelamento:" SIZE 100,8 PIXEL OF oDlg
			@ 53, 15 MSGET cDesMot SIZE 250,10 PICTURE PesqPict("SF3","F3_XDESMOT")  PIXEL
			@ 70,250 BUTTON "&Confirma"   SIZE 36,16 PIXEL ACTION EVAL({|| lConfirm:=.T.,oDlg:End()})
		ELSE
			@ 30, 15 SAY   "Descrição do Motivo de cancelamento:" SIZE 100,8 PIXEL OF oDlg
			@ 38, 15 MSGET cDesMot SIZE 250,10 PICTURE PesqPict("SF3","F3_XDESMOT") PIXEL
			@ 70,250 BUTTON "&Confirma"   SIZE 36,16 PIXEL ACTION EVAL({|| lConfirm:=.T.,oDlg:End()})
		ENDIF
		
		ACTIVATE MSDIALOG oDlg CENTER
		
		//Valida se clicou no botão confirmar
		IF lConfirm
			//Validação para código e motivo
			IF lCodMot .AND. (!Empty(cCodMot) .AND. !Empty(cDesMot))
				lRet:=.T.	
			ElseIF !lCodMot .AND. !Empty(cDesMot)
				lRet:=.T.
			EndIf
		EndIf
		
		If lRet		
			DBSELECTAREA("SF3")
			SF3->(DBSETORDER(5))
			IF SF3->(DBSEEK(XFILIAL("SF3")+SF2->(F2_SERIE+F2_DOC)))
				RECLOCK("SF3",.F.)
				SF3->F3_CODMOT	:= cCodMot
				SF3->F3_XDESMOT := cDesMot
				
				IF CFILANT == "0003"
					SF3->F3_DESCRET	:= "NF CANCELADA"
				ENDIF
					
				SF3->(MSUnlock())
				
				//Gera mensagem de retorno
				U_CFATE04()					
				
			ENDIF
		ELSE
			Aviso("Motivo", "Informe o motivo do cancelamento!", {"Ok"})
		ENDIF
	END
ENDIF

u_GETALLAREA(aArea)
Return  
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} VALCODMOT
Valida o código do motivo de cancelamento
@author  	Carlos Henrique
@since     	01/01/2015
@version  	P.11.8      
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
STATIC FUNCTION VALCODMOT(cTabCodM,cCodMot,cDesCod)
Local lRet:= .T.

DBSELECTAREA("SX5")
SX5->(dbSelectArea(1))  // X5_FILIAL + X5_TABELA + X5_CHAVE

aFWGetSX5 := FWGetSX5(cTabCodM)

For nPos := 1 To Len(aFWGetSX5)

	If  aFWGetSX5[nPos][2]=cTabCodM .And. AllTrim(aFWGetSX5[nPos][3])=AllTrim(cCodMot)
		cDesCod := aFWGetSX5[nPos][4]
	EndIf

Next

If cDesCod = ""
	lRet	:= .F.
	msgalert("Informe um código valido!!")	
ENDIF

RETURN lRet 
