#include "PROTHEUS.CH"
#include "COLORS.CH" 
#include "HEADERGD.CH"   
/*==================================================================================================
  Funcao utilizada para criar roteiros padroes, no caso foi criado um campo no cadastro de processo
  onde deve-se informar se aquele processo será utilizado na criacao dos periodos para a filial,
  pois existem filiais no CIEE que nao tem funcionarios ativos, e nesse caso esta criando os periodos.
@author     Totvs
@since      01/07/2019	
@param
@version    P12
@return
@project
@client    Ciee
@Regra     Cria o menu chamando a rotina customizada.
//==================================================================================================*/
User Function CGPEM23(cPro, cRot, cTip, lAutomato, cSeqPag) 

 	Local cCpartRCJ 	:= ""
 	Local cCpartRCH 	:= ""
 	Local cCpartRFQ 	:= ""
 	Local cCpartRCF 	:= ""
	Local cCpartRCG 	:= ""
	Local cCpartSRY 	:= ""
	Local cCpartSRM 	:= ""
		
	Private cTpCalend 	:=  SuperGetMv( "MV_TPCALEND" , .F. , "1" , )	// 1 = Usa calendario Analitico , 2 = Usa calendario Sintetico  
	Private cQtdeDPer 	:=  SuperGetMv( "MV_DIASPER"  , .F. , "1" , )	// 1 = Usa qtde de dias do mes do periodo , 2 = Usa sempre 30   		

	Private lRobo		:= .F.		//Variável utilizada para o Robô
	Private cNumPag		:= cSeqPag
	Default cPro		:= ""	//Variável utilizada para o Robô
	Default cRot		:= ""	//Variável utilizada para o Robô
	Default cTip		:= ""	//Variável utilizada para o Robô
	Default lAutomato	:= .F.	//Variável utilizada para o Robô
	
	If lAutomato	//Robô?
		Private cProc	:= cPro
		Private cRote	:= cRot
		Private cTipo	:= cTip
		lRobo			:= lAutomato
	Endif
	
	// Limpa variavel n(publica) se existir
    If !( Type( "n" ) == "NIL" )  
    	n := 0
    EndIf 
	
	//-- Verifica o compartilhamento entre as tabelas RCJ, RCH, RFQ, RCF e RCG
  	
	//Modo de compartilhamento da tabela RCJ            
   	cCpartRCJ := FWModeAccess("RCJ", 1)
   	cCpartRCJ += FWModeAccess("RCJ", 2)
   	cCpartRCJ += FWModeAccess("RCJ", 3)
   	
   	//Modo de compartilhamento da tabela RCH
   	cCpartRCH := FWModeAccess("RCH", 1)
   	cCpartRCH += FWModeAccess("RCH", 2)
   	cCpartRCH += FWModeAccess("RCH", 3)
   	
   	//Modo de compartilhamento da tabela RFQ
   	cCpartRFQ := FWModeAccess("RFQ", 1)
   	cCpartRFQ += FWModeAccess("RFQ", 2)
   	cCpartRFQ += FWModeAccess("RFQ", 3)
   	
   	//Modo de compartilhamento da tabela RCF
   	cCpartRCF := FWModeAccess("RCF", 1)
   	cCpartRCF += FWModeAccess("RCF", 2)
   	cCpartRCF += FWModeAccess("RCF", 3)
   	
   	//Modo de compartilhamento da tabela RCG
   	cCpartRCG := FWModeAccess("RCG", 1)
   	cCpartRCG += FWModeAccess("RCG", 2)
   	cCpartRCG += FWModeAccess("RCG", 3)
   	
   	//Modo de compartilhamento da tabela SRY
   	cCpartSRY := FWModeAccess("SRY", 1)
   	cCpartSRY += FWModeAccess("SRY", 2)
   	cCpartSRY += FWModeAccess("SRY", 3)
   	
   	//Modo de compartilhamento da tabela SRM
   	cCpartSRY := FWModeAccess("SRM", 1)
   	cCpartSRY += FWModeAccess("SRM", 2)
   	cCpartSRY += FWModeAccess("SRM", 3)
   	
   	// Verifica se as tabelas estao com o mesmo modo de compartilhamento 
   	If (cCpartRCJ != cCpartRCH) .OR. (cCpartRCJ != cCpartRFQ) .OR. (cCpartRCJ != cCpartRCF) .OR. (cCpartRCJ != cCpartRCG)
   		If !lRobo
   			Help( , , 'HELP', , OemToAnsi("verifique o compartilhamento entre as tabelas RCJ, RCH, RFQ, RCF e RCG. o compartilhamento dessas tabelas deve ser identico."), 1, 0 )    		
		Endif
		Return (.F.)                                          
	EndIf 
	
	If(cCpartSRY > cCpartRCJ) .OR. (cCpartSRM > cCpartSRY)
   		Help( , , 'HELP', , OemToAnsi("verifique o compartilhamento entre as tabelas RCJ, SRY e SRM. o compartilhamento dessas tabelas deve ser hierarquico. Sendo RCJ maior, ou igual, a SRY, e SRY maior ou igual a SRM."), 1, 0 )    		
		Return (.F.)                                          
	EndIf 
   	
	GP490ExecGer() 
											
Return( Nil ) 


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³ GP490ExecGer³ Autor ³ Equipe RH       ³ Data ³  01/02/13   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Exibe tela de parametrizacao.							  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPEA490									                  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function GP490ExecGer()

Local aAdvSize		:= {}	
Local aAreaAlias	:= GetArea()  
Local aInfoAdvSize	:= {}
Local aObjSize		:= {}
Local aObjCoords	:= {}
Local aItens 		:= {"1=SIM","2=NAO"}  
Local nOpcA			:= 0.00		
Local oDlg	
Local oFont
Local oProcesso 
Local oRoteiro
Local oPdPeriodo
Local odDtIni
local oCombo
Local bSet15		:= {|| }
Local bSet24		:= {|| }

Private aRotProc	 := {} 			// Vetor com o roteiro por processo
Private aRG6		 := {}  
Private aRCFMaster	 := {}         // Vetor usado para gravacao dos turnos padroes gerados por registro de periodo
Private aRCGMaster	 := {}         // Vetor usado para gravacao dos itens de calendaerio gerados por turno
Private	aHeaderRCH	 := {} 
Private aColsRCH	 := {} 
Private aRCFHeader	 := {}
Private aRCFCols	 := {}  
Private aRCGAllHeader:= {}  
Private aDuplRCH	 := {}          // Vetor com os registros RCH pre-existentes a geracao de per. padrao
Private cKeySeek	 := ""			// Chave para o Posicionamento no Alias Filho
Private cQuery		 := ""			// Utilizacao de Query para Selecao de Dados
Private cCombo		 := "2"
Private cRoteiro 	 := Space(TamSX3("RCH_ROTEIR")[1]) 			  
Private cProcesso	 := Space(TamSX3("RCH_PROCES")[1]) 
Private cPdPeriodo	 := Space(TamSX3("RCH_PDPERI")[1]) 
Private dParDtIni	 := ""        
Private lTemPadrao	 := .F. 	   		// Indica se tem  padrao de calendario no Roteiros por processo 
Private lRotProc	 := .F.             // Indica se existe conteudo na tabela RGA para gercao                       
Private lDiverge 	 := .F.             // Indica se a data inicial de geracao diverge da ref. grava no cad. de Per.Padrao
Private oGetRCH		 := Nil 			  

// Declaracao de variaveis utilizadas nas funcoes da rotina GPEA400
Private aRCFColsRec	 := {}    
Private aRCGColsRec	 := {}   
Private aRCGColsAll  := {}
Private lGp490 		 := .t. //AllTrim(Upper(FunName())) == "GPEA490" // Indica acesso pela rotina de Ger.Per.Padrao 
Private cFilRFQ		 := xFilial("RCH")   
Private cGp490Mes    := ""
Private cGp490Ano    := ""
Private cGp490Per    := ""
Private cGp490NPg    := ""
Private cGp490DIn	 := CtoD("//")		
Private cGp490DFi    := CtoD("//")                     

Begin Sequence

	// Monta as Dimensoes dos Objetos         					   
	aAdvSize		:= MsAdvSize( , .T., 300)
	aInfoAdvSize	:= { aAdvSize[1] , aAdvSize[2] , aAdvSize[3] , aAdvSize[4] , 10 , 10 }
	aAdd( aObjCoords , { 015 , 020 , .F. , .F. } )
	aAdd( aObjCoords , { 000 , 000 , .T. , .T. } )
	aObjSize		:= MsObjSize( aInfoAdvSize , aObjCoords )            
	
	// Parametros de geracao do periodo padrao                          
	If !lRobo
		DEFINE FONT oFont NAME "Arial" SIZE 0,-11 BOLD 
		DEFINE MSDIALOG oDlg TITLE OemToAnsi("Geração de Período Padrão" ) FROM aAdvSize[7],0 TO aAdvSize[6],aAdvSize[5] OF oMainWnd PIXEL	
        		
			@ aObjSize[1,1]+05, aObjSize[1,2]+30 SAY OemToAnsi("Processo") SIZE 146,10 OF oDlg PIXEL FONT oFont
			@ aObjSize[1,1]+05, aObjSize[1,2]+90 MSGET oProcesso VAR cProcesso SIZE 050,10 OF oDlg PIXEL  F3 'RCJ' VALID ExistCpo('RCJ') .And. fChkRoteiro() PICTURE '@!'	
			
			@ aObjSize[1,1]+25, aObjSize[1,2]+30 SAY OemToAnsi("Roteiro") SIZE 146,10 OF oDlg PIXEL FONT oFont
			@ aObjSize[1,1]+25, aObjSize[1,2]+90 MSGET oRoteiro VAR cRoteiro SIZE 050,10 OF oDlg PIXEL F3 'SRY' VALID  ExistCpo('SRY') .And. fChkRoteiro() PICTURE '@!'
			
			@ aObjSize[1,1]+45, aObjSize[1,2]+30 SAY OemToAnsi("Pad Periodo") SIZE 146,10 OF oDlg PIXEL FONT oFont 		
			@ aObjSize[1,1]+45, aObjSize[1,2]+90 MSGET oPdPeriodo VAR cPdPeriodo SIZE 050,10 OF oDlg PIXEL WHEN(.F.) PICTURE '@!'
			
			@ aObjSize[1,1]+65, aObjSize[1,2]+30 SAY OemToAnsi("Dt Inicio") SIZE 146,10 OF oDlg PIXEL FONT oFont
			@ aObjSize[1,1]+65, aObjSize[1,2]+90 MSGET odDtIni VAR dParDtIni SIZE 050,10 OF oDlg PIXEL  WHEN(.F.) PICTURE '@D'
			
			@ aObjSize[1,1]+85, aObjSize[1,2]+30 SAY OemToAnsi("Todas as Filiais?") SIZE 146,10 OF oDlg PIXEL FONT oFont
			@ aObjSize[1,1]+85, aObjSize[1,2]+90 MSCOMBOBOX oCombo VAR cCombo ITEMS aItens SIZE 050,010 OF oDlg PIXEL  			
			
			bSet15 := { || If( fVldSet15(),( nOpcA := 1.00 , oDlg:End() ), ( nOpcA := 0.00 , .F. ) )}		
			bSet24 := { || nOpcA := 2 , oDlg:End() }

		ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar( oDlg , bSet15 , bSet24 )
	Else
		lGp490 := .T.
		cProcesso	:= cProc
		cRoteiro	:= cRote
		cCombo		:= cTipo
		fChkRoteiro() 
		iif( fVldSet15() , nOpcA := 1.00 , nOpcA := 0.00 )
	Endif 

	If nOpcA == 1 		   
	   If !fPreGeracao()	// Verifica se existem itens ja gravados
	   		Return(.F.)		// Padrão=.F.
	   EndIf
	EndIf 
		
End Sequence

RestArea( aAreaAlias ) 
          
Return ( Nil )  


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³ fVldSet15     ³ Autor ³ Equipe RH     ³ Data ³  01/02/13   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Mostra o grupo de periodos gerados.						  º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPEA490 - Usada na funcao GP490ExecDel.	                  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/ 
Static Function fVldSet15()  

Local aArea	:= GetArea()        
Local lRet	:= .T.         

	// Periodos nao devem  ser montados :                                                
	// - Qdo tem periodo cadastrado para o ano competencia;                              
	// - Qdo nao for selecionado nenhum padrao;                                          
	// - Qdo for selecionado um  padrao e nao tem Roteiro x Processo , porem  ja existe  
	//   periodo cadastrado para o ano competencia.                                      
	If  Empty(cPdPeriodo) .Or. ( !Empty(cPdPeriodo) .And. !lRotProc ) 
	   	MsgAlert(oEmToansi("Aviso") , OemToAnsi("Nao existe periodo padrao cadastrado para esse Roteiro por Processo.") )
		lRet := .F.  
	EndIf 
	
	If lTemPadrao .And. Empty(aRG6)  
		MsgAlert(oEmToansi("Aviso") , OemToAnsi("Nao foi informada a data inicial para a criacao do periodo na rotina de verbas por processo.") )
		lRet := .F. 
	EndIf  
	
	If lDiverge 
		If !MsgYesNo( OemToAnsi("Os dados gerados a seguir apresentam inconsistencias.Verificar cadastro de Periodos Padroes. Deseja continuar?") ) 
		   lRet := .F.                           
		EndIf
	EndIf
	
	RestArea(aArea)
	
Return( lRet )     

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³ fChkRoteiro ³ Autor ³ Equipe RH       ³ Data ³  11/08/07   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Valida exclusao de periodo padrao.						  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPEA400 - Usada na funcao GP400ExecDel.                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/ 
Static Function fChkRoteiro() 

Local lRet:= .T. 
	                           
	CursorWait() // Coloca o Ponteiro do Mouse em Estado de Espera           
	
	If !Empty(cProcesso) .And. !Empty(cRoteiro) 
   		lRotProc := fRotProc()  
	Else       
 		CursorArrow()
		Return(.T.)
	EndIf
	
	// Verifica se tem  Padrao nos Roteiros por Processo 		   
	If !lRotProc 
		If !lRobo
			MsgAlert( OemToAnsi("Aviso") , OemToAnsi("A geracao sera possivel somente para Roteiros por processo que utilizam padrao de periodos") ) 
		Endif
		lRet		:= .F.    		
	Else
		fCarPdRG6()
	EndIf 
	 											   
	CursorArrow() // Restaura o Ponteiro do Mouse

Return( lRet )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³ fRotProc    ³ Autor ³Natie Sugahara      ³ Data ³  04/10/07   º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Verifica se existe um  roteiro por processo cadastrado.       º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPEA400 - Usada na funcao GP400MANU.                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fRotProc()   

	Local aArea			:= GetArea() 
	Local lTemRotProc 	:= .F.  
	
	/*
	aRotProc : { Filial + Processo + Roteiro ;01 - Chave de busca
	               RGA_PDPERI					02 - Pd.Periodo
	               RGA_DTINICP 					03 - Dt.Inicio do Periodo
	               RGA_TOLEPG  					04 - Dias de Tolerancia de Pagto
				     RGA_MODULO 					05 - Modulo/proprietario  
	*/

	aRotProc	:= {}
	
	dbSelectArea("RGA")
	If RGA->(dbSeek( xFilial("RGA") + cProcesso + cRoteiro  ) ) 
		cPdPeriodo		:= RGA->RGA_PDPERI
		If !Empty(cPdPeriodo) 		 
			AADD( aRotProc, {RGA_FILIAL + RGA_PROCES + RGA_CALCUL, RGA_PDPERI, RGA_DTINIC, RGA_TOLEPG, RGA_MODULO} ) 
			dParDtIni := DtoC(aRotProc[1,3])
			lTemRotProc	:= .T. 
		EndIf
		If !Empty(RGA->RGA_PDPERI) .And. !Empty(RG5->RG5_PDPERI)
			lTemPadrao	:= .T. 
		EndIf 	
	Else 
		cPdPeriodo		:= Space(TamSX3("RGA_PDPERI")[1])
		dParDtIni		:= CtoD('//') 
		lTemPadrao		:= .F. 
		lTemRotProc		:= .F.
	EndIf 
	
	RestArea(aArea)  

Return ( lTemRotProc )  

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³ fCarPdRG6   ³ Autor ³Natie Sugahara      ³ Data ³  04/10/07   º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Carrega vetor aRG6 para montar Periodos.					     º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPEA490 								                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function  fCarPdRG6() 
Local aArea			:= GetArea()
Local ckey			:= xFilial("RG6") + cPdPeriodo 
Local cModuloRG6	:= ""    
Local cMesIniPer 	:= ""
Local cMesInicial	:= ""
Local dDtIni		:= CtoD("//")
Local lRet			:= .F. 	 
Local nCnt			:= 0 
Local nDpagto		:= 0
	                              
	If Empty(aRotProc)
		RestArea(aArea)
		Return(lRet)
	EndIf
	
	dDtIni		:= aRotProc[1,3]
	nDpagto		:= aRotProc[1,4]
	cModuloRG6	:= aRotProc[1,5] 
	
	cMesInicial := Strzero(Month(dDtIni), 2)
	
	ckey += cMesInicial
	
	// Carrega vetor para montar Periodos - RG6                     
	dbSelectArea("RG6")
   	RG6->(DbSetOrder(1))
	If RG6->(dbSeek( cKey  ) )  
		aRG6	:= {}
		While RG6->( !Eof() .And. RG6_FILIAL + RG6_PDPERI + RG6_CODIGO = cKey )
			
			IF RG6->RG6_NUMPAG == cNumPag
				nCnt ++	
				dDtFim	:= dDtIni + RG6_DIAPER - 1
				
				AADD(aRG6,{ RG6_PDPERI,;   												// 01 Pd periodo
							StrZero(Year(dDtIni),4) + Strzero(Month(dDtIni), 2),;	// 02 Codigo periodo 200701 
							RG6_NUMPAG,; 												// 03 Num pagto 
							Strzero(Month(dDtIni), 2),;								// 04 Mes 
							Strzero(Year(dDtIni), 4),; 								// 05 Ano 
							dDtIni,;														// 06 Dt Inic 
							dDtFim,;														// 07 Dt fim  
							(dDtFim + nDPagto),; 										// 08 Dt Pagto 
							RG6_CRITER,; 												// 09 Criterio 
							RG6_SEQUE,; 												// 10 Sequencias 
							cModuloRG6,;													// 11 Modulo 
							RG6_DIAPER,;													// 12 Dias Periodo
							RG6_CODIGO })												// 13 Codigo
							
							
				//dDtIni 	:= ( dDtIni + RG6_DIAPER )
				//ckey = xFilial("RG6") + cPdPeriodo + Strzero(Month(dDtIni), 2)
			ENDIF

			RG6->(DbSkip() )
		Enddo
		lRet	:= .T.   
		
		If Len(aRG6) > 1
			cMesIniPer := SubStr(aRG6[1][2],5,2)
			If !(cMesIniPer == cMesInicial)
				lDiverge := .T.  
			EndIf
		EndIf
	EndIf 
	
	RestArea(aArea)  

Return( lRet )



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³ fPreGeracao   ³ Autor ³ Equipe RH     ³ Data ³  10/04/13   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Gera ou nao log pre-geracao.      						  º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPEA490 									                  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/ 
Static Function  fPreGeracao() 

Local cMsgLog		:= "" 
Local cMsgNaoCopia	:= ""
Local cMsgAux		:= "" 
Local lGera 		:= .T.  
Local lRet			:= .T.    
Local nX			:= 0  
Local nUsado 		:= 0     
      
	// Carrega array a ser exibido na Dialog Principal   
	If !lRobo
		MsAguarde({|| GP490MontaCols(cProcesso, cRoteiro, cPdPeriodo , nUsado) },oEmToansi("Aguarde.."),oEmToansi("Geracao em processamento."),.T.)                                 
	Else
		GP490MontaCols(cProcesso, cRoteiro, cPdPeriodo, nUsado)
	Endif
	
	If Len(aDuplRCH) > 0 
		cMsgLog := OemToAnsi("Os periodos abaixo ja estao cadastrados para esse Processo + Roteiro. Ao confirmar a geracao, eles nao serao sobrepostos") + CRLF + OemToAnsi("Para continuar selecione 'Confirmar'.") + CRLF   
											  							  
		For nX := 1 to Len(aDuplRCH)								
			cMsgNaoCopia += aDuplRCH[nX][1]+Space(12-Len(aDuplRCH[nX][1])) + Space(2)								
			cMsgNaoCopia += aDuplRCH[nX][2] + Space(2)								
			cMsgNaoCopia += aDuplRCH[nX][3] + Space(2)
			cMsgNaoCopia += aDuplRCH[nX][4] + Space(2)
			cMsgNaoCopia += aDuplRCH[nX][5] + Space(2)
			cMsgNaoCopia += CRLF	
		Next nX     
		
		If( !Empty(cMsgNaoCopia) )           
			cMsgAux+= Replicate("-", 50)+CRLF
			cMsgAux+= OemToAnsi("Fil.          Proc   Rot  Periodo  Num.Pag")+CRLF  
			cMsgAux+= Replicate("-", 50)+CRLF
			cMsgNaoCopia := cMsgAux + cMsgNaoCopia
		EndIf	    
		
		If !lRobo
			lGera := ShowLog( cMsgLog + cMsgNaoCopia  )
		Endif
	EndIf
	
	If lGera
		If !lRobo
			MsAguarde({|| fDispTelaExcl() },oEmToansi("Aguarde.."),oEmToansi("Geracao em processamento."),.T.) 
		Else
			fDispTelaExcl()
		Endif
	Else
		lRet := .F.
	EndIf

Return( lRet )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³ fDispTelaExcl ³ Autor ³ Equipe RH     ³ Data ³  01/02/13   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Mostra o grupo de periodos gerados.						  º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPEA490 - Usada na funcao GP490ExecDel.	                  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/ 
Static Function  fDispTelaExcl() 

// Variaveis auxiliares
Local nOpcAlt			:= 0.00				// Variavel de controle das alteracoes - utilizada para a gravacao
//Local nX				:= 0.00		
//Local nPosRec			:= 0  

// Variaveis para enchoice da tabela RCH 
Local aRCHAltera		:= {"RCH_PERSEL","RCH_DTPAGO"}	// Vetor com os campos que permitem alteracao
//Local aRCHNotFields		:= {}				// Vetor com os campos que nao serao visualizados
//Local aColsRCHRec		:= {}				// Vetor contendo os recnos dos registros 

// Variaveis da janela 
Local bSet15			:= { || Nil }		// Bloco com as validacoes do botao OK
Local bSet24			:= { || Nil }  		// Bloco com as validacoes do botao Cancelar
Local bDialogInit		:= { || Nil }		// Inicializacao do Dialog

// Variaveis do tipo objetos  
Local oDlg				:= Nil			
Local oFont	
Local oGroup

// Variaveis para controle de coordenadas da janela 
Local aAdvSize			:= {}
Local aInfoAdvSize		:= {}
Local aObjSize			:= {}
Local aObjCoords		:= {}
Local aAdv1Size			:= {}
Local aInfo1AdvSize		:= {}
Local aObj1Coords 		:= {}
Local aObj1Size			:= {}
                     
// Monta as Dimensoes dos Objetos
aAdvSize		:= MsAdvSize()
aInfoAdvSize	:= { aAdvSize[1] , aAdvSize[2] , aAdvSize[3] , aAdvSize[4] , 3 , 3 }					 
aAdd( aObjCoords , { 000 , 025 , .T. , .F. } )		// 1-Cabecalho
aAdd( aObjCoords , { 000 , 000 , .T. , .T. } )		// 2-GetDados
aObjSize		:= MsObjSize( aInfoAdvSize , aObjCoords ) 
	
//Divisao em colunas Linha 1-Dados do Processo+Roteiro
aAdv1Size		:= aClone(aObjSize[1])
aInfo1AdvSize	:= { aAdv1Size[2] , aAdv1Size[1] , aAdv1Size[4] , aAdv1Size[3] , 2 , 2 }
aAdd( aObj1Coords , { 000 , 000 , .T. , .T. } )	// 1-Processo
aAdd( aObj1Coords , { 000 , 000 , .T. , .T. } )	// 2-Roteiro
aAdd( aObj1Coords , { 000 , 000 , .T. , .T. } )	// 3-Per.Padrao
aAdd( aObj1Coords , { 000 , 000 , .T. , .T. } )	// 4-Per.Select.
aObj1Size		:= MsObjSize( aInfo1AdvSize , aObj1Coords,,.T. )   
                                                              
// Define o Bloco para a Inicializacao do Dialog            	   
bDialogInit		:= { ||	CursorWait()							,;	
						EnchoiceBar( oDlg , bSet15 , bSet24 )	,; 
						RstEnchoVlds()							,;	
						CursorArrow()							 ; 
                   }
If !lRobo

	DEFINE FONT oFont NAME "Arial" SIZE 0,-11 BOLD 	
	DEFINE MSDIALOG oDlg TITLE OemToAnsi("Geração de Período Padrão") From aAdvSize[7],0 TO aAdvSize[6],aAdvSize[5] OF oMainWnd PIXEL 
                                       
	@ aObj1Size[1,1] , aObj1Size[1,2]    	GROUP oGroup 	TO aObj1Size[1,3] , aObj1Size[1,4]  LABEL OemToAnsi("Processo") OF oDlg PIXEL 
	@ aObj1Size[1,1]+10 , aObj1Size[1,2]+5 SAY  cProcesso SIZE 045,10 OF oDlg PIXEL FONT oFont
	oGroup:oFont:= oFont	 
	    
	@ aObj1Size[2,1] , aObj1Size[2,2] 		GROUP oGroup 	TO aObj1Size[2,3] , aObj1Size[2,4]  LABEL OemToAnsi("Roteiro") OF oDlg PIXEL 
	@ aObj1Size[2,1]+10 , aObj1Size[2,2]+5 SAY cRoteiro  	SIZE 045,10 OF oDlg PIXEL FONT oFont
	oGroup:oFont:= oFont	
		
	@ aObj1Size[3,1] , aObj1Size[3,2]    	GROUP oGroup 	TO  aObj1Size[3,3] , aObj1Size[3,4] LABEL OemToAnsi("Pad.Periodo") OF oDlg PIXEL	 
	@ aObj1Size[3,1]+10 , aObj1Size[3,2]+5 SAY cPdPeriodo	SIZE 045,10  OF oDlg PIXEL FONT oFont
	oGroup:oFont:= oFont	
				
	@ aObj1Size[4,1] , aObj1Size[4,2]	 	GROUP oGroup 	TO aObj1Size[4,3] , aObj1Size[4,4]  LABEL OemToAnsi("Dt.Inicial ") OF oDlg PIXEL	
	@ aObj1Size[4,1]+10 , aObj1Size[4,2]+5 SAY dParDtIni 	SIZE 045,10 OF oDlg PIXEL FONT oFont
	oGroup:oFont:= oFont
		 		
	oGetRCH := MsNewGetDados():New(aObjSize[2,1],;		// 1  nTop
								 	aObjSize[2,2]	,;  // 2  nLelft
								 	aObjSize[2,3]	,;	// 3  nBottom
	                             	aObjSize[2,4]	,;	// 4  nRright
								 	GD_UPDATE		,;  // 5  Controle do que podera ser realizado na GetDado - nstyle
 									.T.				,;	// 6  Funcao para validar a edicao da linha - ulinhaOK
								 	.T.				,;	// 7  Funcao para validar todas os registros da GetDados - uTudoOK
								 	Nil				,;	// 8  cIniCPOS
								 	aRCHAltera		,;	// 9  aAlter
								 	0			  	,; 	// 10 nfreeze
								 	99999			,;  // 11 nMax
								 	Nil				,;	// 12 cFieldOK
								 	Nil				,;	// 13 usuperdel
								 	Nil				,;	// 14 udelOK
								 	@oDlg			,; 	// 15 Objeto de dialogo - oWnd
								 	@aHeaderRCH    	,;	// 16 Vetor com Colunas - AparHeader
								 	@aColsRCH 	    ,;	// 17 Vetor com Header - AparCols
									            	,;  // 18
									"2")		   		// 19 Tela 	
    
	bSet15	:= {|| nOpcAlt:= 1, If(oGetRCH:TudoOk(),oDlg:End(),nOpcAlt:=0)}
	bSet24	:= {|| oDlg:End()}

	ACTIVATE MSDIALOG oDlg ON INIT Eval( bDialogInit )
Else
	nOpcAlt := 1
Endif   
	
If nOpcAlt == 1 
	 GP490Grava()  // Grava periodos gerados
EndIf 
	
Return( Nil )       

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³ Gp490MontaCols ³ Autor ³ Equipe RH        ³ Data ³  11/09/07   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Monta aCols do RCH.									          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPEA400 - Usada na funcao GPA400MANU.                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/ 
Static Function Gp490MontaCols(cProcesso, cRoteiro, cPdPeriodo , nUsado)	//Padrao e Robô = ok .... "000008" "FOL" "G01" "0"       

// Variaveis utilizadas para RCH
Local aRCHNotFields		:= {}
Local aRCHVirtGd		:= {} 	
Local aRCHVisualGd		:= {} 	

// Variaveis utilizadas para RCF
Local aRCFNotFields		:= {}
Local aRCFVirtGd		:= {}
Local aRCFVisualGd		:= {}
Local nRCFUsado			:= 0  
Local nPosRCF_Tnotra	:= 0

// Variaveis utilizadas para RCG
Local aRCGColsRec		:= {} 
Local aRCGNotFields		:= {}
Local aRCGVirtGd		:= {}
Local aRCGVisualGd		:= {}  
Local nRCGUsa			:= 0

// Variaveis auxiliares
Local cKey				:= ""	
Local lRetOK 			:= .T.      
Local nX				:= 0
Local nRCHUsado			:= 0 	    
Local nPosDtIni			:= 0
Local nPosDtFim			:= 0 
Local nPosPer			:= 0 
Local nPosNumpag		:= 0 
	
	DbSelectArea( "RCH" )
   	DbSetOrder( RetOrder( "RCH", "RCH_FILIAL+RCH_PER+RCH_NUMPAG+RCH_PROCES+RCH_ROTEIR+DTOS(RCH_DTINI)+DTOS(RCH_DTFIM)+RCH_MODULO") ) 
	
	aAdd( aRCHNotFields, "RCH_FILIAL" )   
	aAdd( aRCHNotFields, "RCH_PROCES" )
	aAdd( aRCHNotFields, "RCH_ROTEIR" )  
    
    // Monta componentes RCH
   	aHeaderRCH := GdMontaHeader( 	@nRCHUsado 		,;	//01 -> Por Referencia contera o numero de campos em Uso
									@aRCHVirtGd		,;	//02 -> Por Referencia contera os Campos do Cabecalho da GetDados que sao Virtuais
									aRCHVisualGd	,;	//03 -> Por Referencia contera os Campos do Cabecalho da GetDados que sao Visuais
									"RCH"			,;	//04 -> Opcional, Alias do Arquivo Para Montagem do aHeader
					   				aRCHNotFields	,;	//05 -> Opcional, Campos que nao Deverao constar no aHeader
									Nil				,;	//06 -> Opcional, Carregar Todos os Campos
					   				Nil    			,;	//07 -> Nao Carrega os Campos Virtuais
					   				.T.				,;	//08 -> Carregar Coluna Fantasma e/ou BitMap ( Logico ou Array )
					   				Nil				,;	//09 -> Inverte a Condicao de aNotFields carregando apenas os campos ai definidos
					   				Nil				,;	//10 -> Verifica se Deve Checar se o campo eh usado
					   				Nil				,;	//11 -> Verifica se Deve Checar o nivel do usuario
					   				.T.				,;	//12 -> Utiliza Numeracao na GhostCol
					   				Nil				,;	//13 -> Carrega os Campos de Usuario
					   	   			Nil				 ;  //14 -> Verificar o campo X3_TELA para montagem do Header
					   				)  
									
	aColsRCH 	:= fMontaCols(aRCHNotFields,@nUsado,aHeaderRCH )
	nPosDtIni	:= GdFieldPos("RCH_DTINI"  , aHeaderRCH) 
	nPosDtFim	:= GdFieldPos("RCH_DTFIM"  , aHeaderRCH) 
	nPosPer		:= GdFieldPos("RCH_PER"    , aHeaderRCH) 
	nPosNumpag	:= GdFieldPos("RCH_NUMPAG" , aHeaderRCH) 
	
	dbSelectArea("RCH")
 	RCH->(dbSetOrder(RetOrder("RCH", "RCH_FILIAL+RCH_PER+RCH_NUMPAG+RCH_PROCES+RCH_ROTEIR+DTOS(RCH_DTINI)+DTOS(RCH_DTFIM)+RCH_MODULO")))		
	
	For nX := 1 to Len(aColsRCH) 
		cKey:= xFilial("RCH")+aColsRCH[nX][nPosPer]+aColsRCH[nX][nPosNumPag]+cProcesso+cRoteiro+ DtoS(aColsRCH[nX][nPosDtIni]) + DtoS(aColsRCH[nX][nPosDtFim]) + cModulo
		If (RCH->(dbSeek( cKey ))) 
			AADD(aDuplRCH, {xFilial("RCH"),cProcesso,cRoteiro,aColsRCH[nX][nPosPer], aColsRCH[nX][nPosNumPag] })
		EndIf
	Next nX    
	
	// Monta componentes RCF 
	aAdd( aRCFNotFields , "RCF_FILIAL"  )
	aAdd( aRCFNotFields , "RCF_PER"     )
	aAdd( aRCFNotFields , "RCF_PROCES"  )
	aAdd( aRCFNotFields , "RCF_ROTEIR"  )
	aAdd( aRCFNotFields , "RCF_SEMANA"  ) 
	
	aRCFCols := RCF->( GdMontaCols(@aRCFHeader,;  		// 01 -> Array com os Campos do Cabecalho da GetDados 
									@nRCFUsado,;		// 02 -> Numero de Campos em Uso 
									@aRCFVirtGd,;		// 03 -> [@]Array com os Campos Virtuais 
									@aRCFVisualGd,;		// 04 -> [@]Array com os Campos Visuais 
									"RCF",;				// 05 -> Opcional, Alias do Arquivo Carga dos Itens do aCols 
									@aRCFNotFields,;	// 06 -> Opcional, Campos que nao Deverao constar no aHeader 
									@aRCFColsRec,;		// 07 -> [@]Array unidimensional contendo os Recnos 
									"RCH",;				// 08 -> Alias do Arquivo Pai 
									Nil,;				// 09 -> Chave para o Posicionamento no Alias Filho 
									Nil,;				// 10 -> Bloco para condicao de Loop While 
									Nil,;				// 11 -> Bloco para Skip no Loop While 
									Nil,;				// 12 -> Se Havera o Elemento de Delecao no aCols  
									Nil,;				// 13 -> Se cria variaveis Publicas 
									Nil,;				// 14 -> Se Sera considerado o Inicializador Padrao 
									Nil,;				// 15 -> Lado para o inicializador padrao 
									Nil,;				// 16 -> Opcional, Carregar Todos os Campos 
									Nil,;				// 17 -> Opcional, Nao Carregar os Campos Virtuais 
									Nil,;				// 18 -> Opcional, Utilizacao de Query para Selecao de Dados 
									.F.,;				// 19 -> Opcional, Se deve Executar bKey  ( Apenas Quando TOP ) - utilizado com o parametro 10 
									.F.,;				// 20 -> Opcional, Se deve Executar bSkip ( Apenas Quando TOP ) - utilizado com o parametro 11
									.T.,;				// 21 -> Carregar Coluna Fantasma e/ou BitMap ( Logico ou Array )
									Nil,;				// 22 -> Inverte a Condicao de aNotFields carregando apenas os campos ai definidos
									Nil,;				// 23 -> Verifica se Deve Checar se o campo eh usado
									Nil,;				// 24 -> Verifica se Deve Checar o nivel do usuario
									Nil,;				// 25 -> Verifica se Deve Carregar o Elemento Vazio no aCols
									Nil,;				// 26 -> [@]Array que contera as chaves conforme recnos
									Nil,;				// 27 -> [@]Se devera efetuar o Lock dos Registros
									Nil,;				// 28 -> [@]Se devera obter a Exclusividade nas chaves dos registros
							        Nil,;				// 29 -> Numero maximo de Locks a ser efetuado
									.T.;				// 30 -> Utiliza Numeracao na GhostCol
								);
					   )
	
	// Conter o valor @@@ no Turno de Trabalho
	nPosRCF_Tnotra := GdFieldPos( "RCF_TNOTRA"	, aRCFHeader ) 
	aRCFCols[1, nPosRCF_Tnotra] := "@@@"	// Codigo generico para todos os turnos
	   
	// Monta componentes RCG 
	aAdd( aRCGNotFields , "RCG_FILIAL"  )
	aAdd( aRCGNotFields , "RCG_TNOTRA"  )
	aAdd( aRCGNotFields , "RCG_PER"     )
	aAdd( aRCGNotFields , "RCG_SEMANA"  )	
	aAdd( aRCGNotFields , "RCG_PROCES"  )
	aAdd( aRCGNotFields , "RCG_ROTEIR"  )
	aAdd( aRCGNotFields , "RCG_MES"     )
	aAdd( aRCGNotFields , "RCG_ANO"     )

	RCG->( dbSetOrder( RetOrdem( "RCG" , "RCG_FILIAL+RCG_PROCES+RCG_PER+RCG_SEMANA+RCG_ROTEIR+RCG_TNOTRA" ) ) )
	aRCGColsAll := GdMontaCols( ;
									@aRCGAllHeader,;	//01 -> Array com os Campos do Cabecalho da GetDados
					   	 			@nRCGUsa,;			//02 -> Numero de Campos em Uso
					 				@aRCGVirtGd,;		//03 -> [@]Array com os Campos Virtuais
					 				@aRCGVisualGd,;		//04 -> [@]Array com os Campos Visuais
					 				"RCG",;				//05 -> Opcional, Alias do Arquivo Carga dos Itens do aCols
					 				Nil,;				//06 -> Opcional, Campos que nao Deverao constar no aHeader
					 				@aRCGColsRec,;		//07 -> [@]Array unidimensional contendo os Recnos
	  								"RCG",;				//08 -> Alias do Arquivo Pai
	  				 				cKey,;				//09 -> Chave para o Posicionamento no Alias Filho
	  				 				Nil,;				//10 -> Bloco para condicao de Loop While
		  			 				Nil,;				//11 -> Bloco para Skip no Loop While
		  			 				.T.,;				//12 -> Se Havera o Elemento de Delecao no aCols
		  			 				Nil,;				//13 -> Se cria variaveis Publicas
		  			 				Nil,;				//14 -> Se Sera considerado o Inicializador Padrao
		  			 				Nil,;				//15 -> Lado para o inicializador padrao
		  			 				.T.,;				//16 -> Opcional, Carregar Todos os Campos
		  			 				Nil,;				//17 -> Opcional, Nao Carregar os Campos Virtuais
					 				Nil,;				//18 -> Opcional, Utilizacao de Query para Selecao de Dados
					 				.F.,;				//19 -> Opcional, Se deve Executar bKey  ( Apenas Quando TOP )
					 				.F.,;				//20 -> Opcional, Se deve Executar bSkip ( Apenas Quando TOP )
					 				.T.,;				//21 -> Carregar Coluna Fantasma
									Nil,;				//22 -> Inverte a Condicao de aNotFields carregando apenas os campos ai definidos
									Nil,;				//23 -> Verifica se Deve Checar se o campo eh usado
									Nil,;				//24 -> Verifica se Deve Checar o nivel do usuario
									Nil,;				//25 -> Verifica se Deve Carregar o Elemento Vazio no aCols
									Nil,;				//26 -> [@]Array que contera as chaves conforme recnos
									Nil,;				//27 -> [@]Se devera efetuar o Lock dos Registros
									Nil,;				//28 -> [@]Se devera obter a Exclusividade nas chaves dos registros
							        Nil,;				//29 -> Numero maximo de Locks a ser efetuado
									.T.;				//30 -> Utiliza Numeracao na GhostCol
						 			) 

     // Calcula itens de calendario
     fGerCalen()
         
Return( lRetOK )  

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³ fMontaCols  ³ Autor ³ Equipe RH         ³ Data ³  04/02/13   º±±  
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Gera aCols com conteudo.									    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPEA490 												        º±± 
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function  fMontaCols(	aNotFields 		,;		// Campos nao visuais de RCG
					   			nUsado			,;		// Numero de campos usados - RCG
								aHeaderRCH		;		// aHeader - RCH    
								)
Local aColsAux		:= {}
Local aRelacaoNew	:= {}
Local cAliasAtu 	:= ""	
Local nTam			:= 0 	                                 
Local nPosGhost		:= 0 	
Local nPosPer		:= 0 
Local nPosNPag		:= 0
Local nPosMes		:= 0
Local nPosAno		:= 0
Local nPosDtIni		:= 0
Local nPosDtFim		:= 0
Local nPosDtPag 	:= 0
Local nPosPdPeri 	:= 0 
Local nPosMod		:= 0 
Local nPosCrit  	:= 0
Local nPosSequ   	:= 0
Local nPosAli		:= 0
Local nPosRecWt		:= 0
Local nX			:= 0 	
Local nPer			:= 0 
 	
	cAliasAtu 	:= "RCH"									
	nTam		:= Len(aHeaderRCH)+1
	nPosPer		:= GdFieldPos("RCH_PER"    , aHeaderRCH)
	nPosNPag	:= GdFieldPos("RCH_NUMPAG" , aHeaderRCH)
	nPosMes		:= GdFieldPos("RCH_MES"    , aHeaderRCH)
	nPosAno		:= GdFieldPos("RCH_ANO"    , aHeaderRCH)
	nPosDtIni	:= GdFieldPos("RCH_DTINI"  , aHeaderRCH)
	nPosDtFim	:= GdFieldPos("RCH_DTFIM"  , aHeaderRCH)
	nPosDtPag 	:= GdFieldPos("RCH_DTPAGO" , aHeaderRCH) 
	nPosMod   	:= GdFieldPos("RCH_MODULO" , aHeaderRCH)
	nPosPdPeri 	:= GdFieldPos("RCH_PDPERI" , aHeaderRCH) 
	nPosCrit  	:= GdFieldPos("RCH_CRITER" , aHeaderRCH)
	nPosSequ   	:= GdFieldPos("RCH_SEQUE"  , aHeaderRCH)		
	nPosGhost	:= GdFieldPos("GHOSTCOL"   , aHeaderRCH)
	nPosAli		:= GdfieldPos("RCH_ALI_WT" , aHeaderRCH)
	nPosRecWt	:= GdfieldPos("RCH_REC_WT" , aHeaderRCH)
     
	nPer		:= Len(aRG6) 
	aColsAux	:= Array(nPer, nTam )
	
	aRelacaoNew := GdRmkaCols(	aHeaderRCH, .F.,	.T., .T. )
	
	For nX := 1 to nPer		
		nUsado 	:= 0      
		
		dbSelectArea("SX3")
		dbSetOrder(1)
		SX3->(MsSeek("RCH" , .F.)) 
		While !Eof() .And. X3_ARQUIVO == cAliasAtu 
			If x3uso(X3_USADO) .And. cNivel >= X3_NIVEL  .and. !aScan(aNotFields,AllTrim(X3_CAMPO)) > 0 
				If 	alltrim(X3_CAMPO) == "RCH_PDPERI" .And. nPosPdPeri > 0 
					aColsAux[nX, nPosPdPeri]	:= aRG6[nX, 1]                 	// Pad.Periodo 
				ElseIf alltrim(X3_CAMPO) == "RCH_PER" .And. nPosPer > 0
					aColsAux[nX, nPosPer]		:= aRG6[nX, 2]					// Ex.: 200701 
				ElseIf alltrim(X3_CAMPO) == "RCH_NUMPAG" .And. nPosNPag > 0
					aColsAux[nX, nPosNPag]		:= aRG6[nX, 3]                 // No Pagto
				ElseIf alltrim(X3_CAMPO) == "RCH_MES"	.And. nPosMes > 0
					aColsAux[nX, nPosMes]		:= aRG6[nX, 4] 					// Mes
				ElseIf alltrim(X3_CAMPO) == "RCH_ANO" .And. nPosAno > 0 	
					aColsAux[nX, nPosAno]		:= aRG6[nX, 5]					// Ano 		
				ElseIf alltrim(X3_CAMPO) == "RCH_DTINI"	 .And. nPosDtIni > 0 
					aColsAux[nX, nPosDtIni]		:= aRG6[nX, 6]					// Dt Inicio Periodo
				ElseIf alltrim(X3_CAMPO) == "RCH_DTFIM"	 .And. nPosDtFim > 0 
					aColsAux[nX, nPosDtFim]		:= aRG6[nX, 7]					// Dt Fim  Periodo
				ElseIf 	alltrim(X3_CAMPO) == "RCH_DTPAGO" .And. nPosDtFim > 0	
					aColsAux[nX, nPosDtPag]		:= aRG6[nX, 8]					// Data de pagto
				ElseIf 	alltrim(X3_CAMPO) == "RCH_CRITER" .And. nPosCrit> 0  
					aColsAux[nX, nPosCrit]		:= aRG6[nX, 09]                	// Criterio 
				ElseIf 	alltrim(X3_CAMPO) == "RCH_SEQUE" .And. nPosSequ > 0  
					aColsAux[nX, nPosSequ]		:= aRG6[nX, 10]                // Sequencia 
				ElseIf 	alltrim(X3_CAMPO) == "RCH_MODULO" .And. nPosMod > 0  
					aColsAux[nX, nPosMod]		:= aRG6[nX, 11]               	// Modulo 
				Else
					nUsado := GdfieldPos(X3_CAMPO , aHeaderRCH)
					If nUsado > 0  
						aColsAux[nX,nUsado] := aRelacaoNew[1,nUsado]
					EndIf
				EndIf
				
			EndIf
			SX3->(dbSkip())
		EndDo  
		
		If nPosAli > 0
			aColsAux[nX,nPosAli] := cAliasAtu
		EndIf   
		
		If nPosRecWt > 0 
			aColsAux[nX,nPosRecWt] := 0
		EndIf    
		
	 	aColsAux[nX,nPosGhost] 	 := StrZero(0,10)
		aColsAux[nX,nTam       ] := .F.	
	Next nX


Return( aClone(aColsAux) )           

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³ GP490Grava  ³ Autor ³ Equipe RH			³ Data ³  04/02/2013 º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Gravacao da Rotina de Geracao de Periodos Padroes.            º±± 
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPEA490                                                       º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function GP490Grava()

Local aColsCopia	:= aClone(aColsRCH)
Local aColsRCH 		:= {}
Local aFiliais		:= {}
Local aRelacoes		:= fBuscaRel()   
Local cKey			:= ""
Local cFilAux		:= cFilAnt    	
Local lGravaRCH		:= .F.
Local lOk			:= .T.  
//Local nChoice		:= 0	
//Local nChoices		:= 0.00					
Local nX			:= 0			
Local nY			:= 0       
//Local nCont			:= 0
Local nFil			:= 0
Local nPosRec		:= 0	   
Local nPosPer		:= 0	   
Local nPosNumPg		:= 0	 
Local nPosMes		:= 0	  
Local nPosAno		:= 0	  
Local nPosDtIni		:= 0	  
Local nPosDtFim		:= 0 
Local nPosModulo	:= 0	   
Local lgrvOK		:= .F.

If !lRobo
	nPosRec		:= GdfieldPos("RCH_REC_WT"	, oGetRCH:aHeader)	   
	nPosPer		:= GdfieldPos("RCH_PER"		, oGetRCH:aHeader)	   
	nPosNumPg	:= GdfieldPos("RCH_NUMPAG"	, oGetRCH:aHeader)	 
	nPosMes		:= GdfieldPos("RCH_MES"		, oGetRCH:aHeader)	  
	nPosAno		:= GdfieldPos("RCH_ANO"		, oGetRCH:aHeader)	  
	nPosDtIni	:= GdfieldPos("RCH_DTINI"	, oGetRCH:aHeader)	  
	nPosDtFim	:= GdfieldPos("RCH_DTFIM"	, oGetRCH:aHeader) 
	nPosModulo	:= GdfieldPos("RCH_MODULO"	, oGetRCH:aHeader)

	nHeadersRCH	:= Len(oGetRCH:aHeader) 
	aColsRCH 	:= aClone(oGetRCH:aCols) 
	nCols		:= Len(oGetRCH:aCols)
Else
	nPosRec		:= aScan( aHeaderRCH, { |x| x[2] == "RCH_REC_WT"})	   
	nPosPer		:= aScan( aHeaderRCH, { |x| x[2] == "RCH_PER" 	})		   
	nPosNumPg	:= aScan( aHeaderRCH, { |x| x[2] == "RCH_NUMPAG"})		 
	nPosMes		:= aScan( aHeaderRCH, { |x| x[2] == "RCH_MES" 	})		  
	nPosAno		:= aScan( aHeaderRCH, { |x| x[2] == "RCH_ANO" 	})		  
	nPosDtIni	:= aScan( aHeaderRCH, { |x| x[2] == "RCH_DTINI" })		  
	nPosDtFim	:= aScan( aHeaderRCH, { |x| x[2] == "RCH_DTFIM" })	 
	nPosModulo	:= aScan( aHeaderRCH, { |x| x[2] == "RCH_MODULO"})

	nHeadersRCH	:= Len(aHeaderRCH) 
	aColsRCH 	:= aClone(aColsCopia) 
	nCols		:= Len(aColsCopia)
Endif

If cCombo == "2"
	aAdd(aFiliais,xFilial("RFQ"))
Else
	CargaFiliais(@aFiliais)
EndIf
	
cFilRFQ	:= "######" 
		
Begin Transaction
	For nFil := 1 to Len(aFiliais)
		
		cFilAnt := aFiliais[nFil]
			
		DbSelectArea("RCJ")
		DbSetOrder(1)
		If !DbSeek(xFilial("RCJ")+cProcesso) //Se nao existir o processo na filial, nao grava o periodo
			Loop
		EndIf  

		DbSelectArea("SRY")
		DbSetOrder(1)
		If !DbSeek(xFilial("SRY")+cRoteiro) //Se nao existir o roteiro na filial, nao grava o periodo
			Loop
		EndIf
		
		If cFilRFQ == xFilial("RFQ")
			Loop
		EndIf

		If !(aScan( aRelacoes, { |x| x[1] == XFILIAL("RGA") .AND. x[2] == cProcesso .AND. x[3] == cRoteiro .AND. x[4] == cPdPeriodo } ))
			Loop
		Endif
			
		cFilRFQ := xFilial("RFQ")			     
    				  
	    // Gravacao dos registros de periodo
		For nX := 1 To nCols    
			
			dbSelectArea("RFQ")
		    dbSetOrder(1) // Filial + Processo + Periodo + Numero de Pagamento + Dt Inifial + Dt Final + Modulo
			
			If !lRobo
				cKey := xFilial("RCH") + cProcesso + oGetRCH:aCols[nX,nPosPer] + oGetRCH:aCols[nX,nPosNumPg] + DtoS(oGetRCH:aCols[nX,nPosDtIni]) + ;
						DtoS(oGetRCH:aCols[nX,nPosDtFim]) + oGetRCH:aCols[nX,nPosModulo]
			Else
				cKey := xFilial("RCH") + cProcesso + aColsRCH[nX,nPosPer] + aColsRCH[nX,nPosNumPg] + DtoS(aColsRCH[nX,nPosDtIni]) + ; 			
						DtoS(aColsRCH[nX,nPosDtFim]) + aColsRCH[nX,nPosModulo]
			Endif
			
			If !RFQ->(MsSeek(cKey , .F.))
				RecLock( "RFQ" , .T. , .F. ) // Inclusao  
				RFQ->RFQ_FILIAL := xFilial("RCH")  
				RFQ->RFQ_PROCES := cProcesso
				RFQ->RFQ_MES 	:= IIF(	!lRobo , oGetRCH:aCols[nX,nPosMes] 		, aColsRCH[nX,nPosMes])
				RFQ->RFQ_ANO 	:= IIF( !lRobo , oGetRCH:aCols[nX,nPosAno]		, aColsRCH[nX,nPosAno])
				RFQ->RFQ_PERIOD := IIF( !lRobo , oGetRCH:aCols[nX,nPosPer]		, aColsRCH[nX,nPosPer]) 
				RFQ->RFQ_NUMPAG := IIF( !lRobo , oGetRCH:aCols[nX,nPosNumPg]	, aColsRCH[nX,nPosNumPg])
				RFQ->RFQ_DTINI 	:= IIF( !lRobo , oGetRCH:aCols[nX,nPosDtIni]	, aColsRCH[nX,nPosDtIni])
				RFQ->RFQ_DTFIM 	:= IIF( !lRobo , oGetRCH:aCols[nX,nPosDtFim]	, aColsRCH[nX,nPosDtFim]) 
				RFQ->RFQ_MODULO	:= IIF( !lRobo , oGetRCH:aCols[nX,nPosModulo]	, aColsRCH[nX,nPosModulo])
				RFQ->( MsUnlock() ) 
		    EndIf 	     

			RFQ->(dbCloseArea()	)
			
			dbSelectArea("RCH")   
			dbSetOrder(RetOrder("RCH","RCH_FILIAL+RCH_PER+RCH_NUMPAG+RCH_PROCES+RCH_ROTEIR+DTOS(RCH_DTINI)+DTOS(RCH_DTFIM)+RCH_MODULO"))  
			
			If !lRobo
				cKey := xFilial("RCH") + aCols[ nX, nPosPer] + oGetRCH:aCols[ nX, nPosNumPg] + cProcesso + cRoteiro + ;
						DtoS(oGetRCH:aCols[ nX, nPosDtIni]) + DtoS(oGetRCH:aCols[ nX, nPosDtFim]) + oGetRCH:aCols[ nX, nPosModulo]
			Else
				cKey := xFilial("RCH") + aColsRCH[ nX, nPosPer] + aColsRCH[ nX, nPosNumPg] + cProcesso + cRoteiro + ;
						DtoS(aColsRCH[ nX, nPosDtIni]) + DtoS(aColsRCH[ nX, nPosDtFim]) + aColsRCH[ nX, nPosModulo]			
			Endif
			
			// Ao existir registro de periodo gravado, pula gravacao na tabela RCH			
		   	If !RCH->(MsSeek(cKey , .F.))   
				lGravaRCH 	:= .T.
		    Else
		    	lGravaRCH	:= .F.
			EndIf  
				
			// Carrega campos chaves para correta gravacao dos periodos gerados na tabela RCF/RCG
			fLoadChav(aColsRCH[nX])         
				                 			
			If lGravaRCH 
				RecLock( "RCH" , .T. , .F. )
				RCH->RCH_FILIAL := xFilial("RCH")
				RCH->RCH_PROCES := cProcesso
				RCH->RCH_ROTEIR := cRoteiro 
				RCH->RCH_PDPERI := cPdPeriodo
					
				For nY := 1 To nHeadersRCH
					
					If !lRobo
						cCampo := Trim(oGetRCH:aHeader[nY][2]) 
					Else
						cCampo := Trim(aHeaderRCH[nY][2])					
					Endif
										
					xConteudo := aColsRCH[nX,nY]
					
					If cCampo == "RCH_REC_WT" .And. xConteudo = 0 
						If !lRobo	
							nPosRecWt	:= GdfieldPos("RCH_REC_WT" , oGetRCH:aHeader) 
						Else
							nPosRecWt	:= GdfieldPos("RCH_REC_WT" , aHeaderRCH)
						Endif
						xConteudo 	:= RCH->(Recno())  
					Else  
						If cCampo == "RCH_MODULO"
							xConteudo := cModulo							
						Else 	 
							xConteudo := aColsRCH[nX,nY] 
						EndIf 
					EndIf
						 	 
					&cCampo := xConteudo 
				Next nY
			EndIf 	

			RCH->( MsUnlock() )
			//RCH->(dbCloseArea()	) 
							
			// Gravacao dos registros de turno  
			dbSelectArea("RCF")
			dbSetOrder(RetOrder("RCF","RCF_FILIAL+RCF_PER+RCF_SEMANA+RCF_ANO+RCF_MES+RCF_PROCES+DTOS(RCF_DTINI)+DTOS(RCF_DTFIM)+RCF_MODULO")) 
			
			If !lRobo
				cKey := xFilial("RCH") + oGetRCH:aCols[nX,nPosPer] + oGetRCH:aCols[nX,nPosNumPg] + oGetRCH:aCols[nX,nPosAno]  + ;
						oGetRCH:aCols[nX,nPosMes] + cProcesso + DtoS(oGetRCH:aCols[nX,nPosDtIni]) + DtoS(oGetRCH:aCols[nX,nPosDtFim]) + oGetRCH:aCols[nX,nPosModulo]
	 		Else
	 			cKey := xFilial("RCH") + aColsRCH[nX,nPosPer] + aColsRCH[nX,nPosNumPg] + aColsRCH[nX,nPosAno]  + ;
	 					aColsRCH[nX,nPosMes] + cProcesso + DtoS(aColsRCH[nX,nPosDtIni]) + DtoS(aColsRCH[nX,nPosDtFim]) + aColsRCH[nX,nPosModulo]	 		
	 		Endif
	 		
			// Condicoes para gravacao de Turno Padrao "@@@":
			// 1. Ao nao encontrar registro(s) de turno cadastrado(s),
			// 2. Ao encontrar registro(s) de turno cadastrado(s) SEM item de calendario sendo 
			// MV_TPCALEN =  1 (ou seja, fora gravado com tipo de calendario Sintetico).
			If !RCF->(MsSeek(cKey , .F.))
				// Grava Turno Padrao "@@@" 
				fGravaRCF(aRCFMaster[nX],,Len(aRCFHeader))	
			ElseIf cTpCalend == "1"  
				// Condicoes para gravacao de Itens de Calendario:
				// 1. Quando nao possuir outros registros gravados previamente
				// 2. Se exister registros gravados previamente que nao sejam de turno padrao - "@@@"
				dbSelectArea("RCG")
				dbSetOrder(RetOrder("RCG","RCG_FILIAL+RCG_PER+RCG_SEMANA+RCG_ANO+RCG_MES+RCG_PROCES+DTOS(RCG_DTINI)+DTOS(RCG_DTFIM)+RCG_MODULO")) 
			 	If !RCG->( MsSeek( cKey , .F. ) )	  
			 		// Removo quaisquer registro de turno pre-existentes	            	 
            	  	fAlterRCF(2,5)       
            	  	// Gravo  Turno Padrao "@@@" 
	            	fGravaRCF(aRCFMaster[nX],,Len(aRCFHeader))		            
	            Else
	            	// Deleta itens nos arrays de gravacao ref. a Turno e Itens de Calendario do item pre-existente   
	            	If !lRobo
	            		fDelTurnItens(oGetRCH:aCols[ nX, nPosAno]+oGetRCH:aCols[ nX, nPosMes]+oGetRCH:aCols[ nX, nPosPer], nX)
	    			Else
	    				fDelTurnItens(aColsRCH[ nX, nPosAno]+aColsRCH[ nX, nPosMes]+aColsRCH[ nX, nPosPer], nX)
	    			Endif
	    		EndIf		            	
	    		RCG->(dbCloseArea()	)
	    	EndIf
	        lgrvOK := .T.
	        RCF->(dbCloseArea()	) 
	    Next nX
			
		// Gravacao de itens de calendario se tipo Analitico
		If cTpCalend == "1" 
			fGravaRCG()
		EndIf
			
	Next nFil 
		
End Transaction
	
cFilAnt := cFilAux  

if lgrvOK 
    // Ajusta campo no calendario para os horistas.
    //U_CGPEM16()                                    
    If !lRobo
		MsgAlert(oEmToansi("Aviso") , OemToAnsi("Periodos gerados com sucesso! Para visualizar os registros com Turno e Calendario Padrao cadastrados acesse a rotina de Periodos.")) 	
	else
		conout("Periodos gerados com sucesso! Para visualizar os registros com Turno e Calendario Padrao cadastrados acesse a rotina de Periodos.") 	
	endif		
Else 
	MsgAlert(oEmToansi("Aviso") , oEmToansi("Os dados não foram gerados devido a inconsistências no processo."))   
Endif 

Return( lOk )               

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³ fGerCalen   ³ Autor ³ Equipe RH         ³ Data ³  05/02/13   º±±  
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Gerar conteudo nos arrays utilizados para gravacao RCF/RCG.  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPEA490												        º±± 
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fGerCalen()

Local nX 		:= 0  
Local nPosDtIni		:= GdfieldPos("RCH_DTINI",aHeaderRCH) 
Local nPosDtFim		:= GdfieldPos("RCH_DTFIM",aHeaderRCH) 	 
    
    // Executa calculo e agregacao de valor no aCols    
    // Apos calculos estara carregado o array aRCGColsAll 
	For nX := 1 to Len(aColsRCH)
		dRFQDtIni 	:= If(nPosDtIni > 0 , aColsRCH[nX][nPosDtIni], )	//Robô:01-01-2016
		dRFQDtFim 	:= If(nPosDtFim > 0 , aColsRCH[nX][nPosDtFim], ) 	//Robô:31-01-2016
		
		// Carrega campos chaves para correta gravacao dos periodos gerados no array aRCGMaster
		fLoadChav(aColsRCH[nX])															//ROBO .T.    
		fFeriado( xFilial("SP3"),,,dRFQDtIni,dRFQDtFim) // Carrega __aFeriadoStatic		//ROBO .F.
		fCalcSint() 
	Next nX    
	aRCGColsAll := aClone(aRCGMaster)
 
Return( .T. )   

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³ fDelTurnItens ³ Autor ³ Equipe RH       ³ Data ³  08/04/13   º±±  
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Deleta conteudo de periodo duplicado nos arrays utilizados   º±±
±±º          ³ para gravacao das tabelas RCF/RCG. 							º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPEA490												        º±± 
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function fDelTurnItens(cKeyRCG, nItem)   
Local aArea			:= GetArea()
Local nX 			:= 0  
Local nMesRCG		:= GdfieldPos("RCG_MES",aRCGAllHeader) 
Local nAnoRCG		:= GdfieldPos("RCG_ANO",aRCGAllHeader) 	 
Local nPerRCG		:= GdfieldPos("RCG_PER",aRCGAllHeader) 	 
    
    // Para exclusao do respectivo item no array aRCFMaster, considerar
    // a posicao do elemento no array aColsRCH, por exemplo, se for o elemento 5
    // o elemento 5 do array aRCFMaster e que devera ser deletado.
    If Len(aRCFMaster) >= nItem        
    	// Seta array do nItem como deletado
    	 aRCFMaster[nItem][Len(aRCFMaster[nItem])] := .T.
    EndIf
    
    // Para exclusao na tabela RCG considerar 3 chaves = Ano+Mes+CodPeriod     
    If nMesRCG > 0 .And. nAnoRCG > 0 .And. nPerRCG > 0
		For nX := 1 to Len(aRCGColsAll)  
			If cKeyRCG == aRCGColsAll[nX][nAnoRCG] + aRCGColsAll[nX][nMesRCG] + aRCGColsAll[nX][nPerRCG]
				aRCGColsAll[nX][Len(aRCGColsAll[nX])] := .T.
	        EndIf
		Next nX   
	EndIf        
	
	RestArea(aArea)
 
Return( .T. )   

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³ ShowLog  ³ Autor ³ Equipe RH          ³ Data ³  10/04/13   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Exibe mensagem de log de ocorrencias pre-geracao.          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPEA490                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function ShowLog(cMemo)     
Local lOk	:= .T.
Local oDlg    
//Local oGroup
Local oMemo
Local oFont
Local oPanel
//Local oBar1
//Local oBtn_OK
Local nOpca  := 0 
Local bSet15 := {|| NIL}
Local bSet24 := {|| NIL} 

// Variaveis para Dimensionar Tela
Local aAdvSize		:= {}
Local aInfoAdvSize	:= {}
Local aObjSize		:= {}
Local aObjCoords	:= {}

Default cMemo := ""

	Begin Sequence	     

		// Monta as Dimensoes dos Objetos         					   
		aAdvSize		:= MsAdvSize()
		aAdvSize[5] 	:= (aAdvSize[5]/100) * 57.2
		aAdvSize[6] 	:=  (aAdvSize[6]/100) * 57
		aInfoAdvSize	:= { aAdvSize[1] , aAdvSize[2] , aAdvSize[3] , aAdvSize[4] , 0 , 0 }
		aAdd( aObjCoords , { 015 , 020 , .T. , .F. } )
		aAdd( aObjCoords , { 000 , 000 , .T. , .T. } )
		aObjSize		:= MsObjSize( aInfoAdvSize , aObjCoords )
		
		DEFINE FONT oFont NAME "Courier New" SIZE 0,-11 BOLD
		DEFINE MSDIALOG oDlg TITLE OemToAnsi("Log de ocorrencias - Pre Geracao") From aAdvSize[7],0 TO aAdvSize[6],aAdvSize[5] OF oMainWnd PIXEL 
		                      
			//Barra de Ferramentas
			oPanel:= TPanel():New(	 0,;
									 0,;
									 NIL,;
									 oDlg,;
									 ,;
									 ,;
									 ,;
									 ,;
									 ,;
									 200,;
									 15,;
									 .F.,;
									 .F.;
									 )
		         
			@ aObjSize[1,3]*0.75, aObjSize[1,4]*0.014 GET oMemo VAR cMemo MEMO SIZE aObjSize[1,4]*0.55, aObjSize[1,4]*0.19 FONT oFont HSCROLL CENTERED DESIGN NO VSCROLL OF oDlg PIXEL WHEN ( .T. )
			oMemo:lReadOnly := .T.
		    
		    bSet15 := { || nOpcA := 1 , oDlg:End()}
			bSet24 := { || nOpcA := 0 , oDlg:End() }
	         	
		ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar( oDlg , bSet15 , bSet24 )    
		
		If !(nOpcA == 1)
			lOk	:= .F.
		EndIf
	
	End Sequence 
	
Return( lOk )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³ CargaFiliais  ³ Autor ³ Leandro Dr.   ³ Data ³  10/04/13   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Carrega filiais para gravacao do periodo			          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ GPEA490                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function CargaFiliais(aFiliais)
Local aArea		:= GetArea()
Local aAreaSM0	:= SM0->(GetArea())
Local cFilAux	:= cFilAnt

DbSelectArea("SM0")
DbGoTop()

While SM0->(!Eof())
	If SM0->M0_CODIGO == cEmpant
		aAdd(aFiliais,FWGETCODFILIAL) 	        	
	EndIf
	SM0->(dbSkip())	
EndDo

cFilAnt := cFilAux

RestArea(aAreaSM0)
RestArea(aArea)

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} fBuscaRel
Busca relações de roteiro e padrões de período e insere em um array
@author  Rafael Reis
@since   19/04/2018
@version P12.1.17
/*/
//-------------------------------------------------------------------
Static Function fBuscaRel()
Local aResult 		:= 	{}
Local cQuery		:= "SELECT * FROM " + RetSqlName("RGA") + " WHERE D_E_L_E_T_ = ''"
Local cAlias		:=	GetNextAlias()
cQuery := ChangeQuery(cQuery)
dbUseArea(.T.,'TOPCONN', TCGenQry(,,cQuery),cAlias, .F., .T.)
While (cAlias)->(!Eof())
	Aadd( aResult, { (cAlias)->(RGA_FILIAL), (cAlias)->(RGA_PROCES), (cAlias)->(RGA_CALCUL), (cAlias)->(RGA_PDPERI) } )
	(cAlias)->(dbSkip())
EndDo
(cAlias)->(dbCloseArea())
Return aResult
