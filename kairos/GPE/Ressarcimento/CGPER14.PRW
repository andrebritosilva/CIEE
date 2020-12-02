#Include "PROTHEUS.CH"
#Include "TOPCONN.CH"
#Include "rwmake.ch"     
#Include 'REPORT.CH'      
#Include "FIVEWIN.CH"           

#DEFINE ENTER chr(13)+chr(10)

/*==================================================================================================
  Relatorio de ressarcimento de despesas 
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee
@fontes    CGPER14.PRW + CGPER21.PRW + CGPE21.PRW + CGPER21.rptdesign 
//================================================================================================== */
User Function CGPER14()

//Define Variaveis Locais (Programa)                           
Local nOpca		:= 0
Local aSays		:= {}
Local aButtons	:= {}  

// Declara Variaveis
Private cPerg    	:= Padr("CGPER14",10)
Private nTamFil     := TamSX3("RA_FILIAL")[1]
Private nTamMat     := TamSX3("RA_MAT")[1]
Private nTamSet     := TamSX3("RA_XSETOR")[1]
Private nTamNom     := TamSX3("RA_NOME")[1]
Private nTamCC      := TamSX3("RA_CC")[1]
Private nTmLt  		:= TamSX3("ZZC_GRUPO")[1]//TamSX3("ZZH_CODIGO")[1]  
Private aLog		:= {}
Private nContRegs   := 0
Private nContTotal  := 0 
Private nRetroage   := SuperGetMv("ES_MESANTE",.f.,0)
Private cWTabAlias  
Private nHdlLog

cCadastro  			:= "Relatório de Ressarcimento de Despesas"

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ?
//?Valida a pergunta                                                   ?
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ? 
fChkPerg()  

Pergunte(cPerg,.F.)

AADD(aSays,"Esta rotina gerará os arquivos em PDF referentes ao ")
AADD(aSays,"ressarcimento conforme parâmetros informados pelo")
AADD(aSays,"usuário.")

AADD(aButtons, { 5,.T.,{|| Pergunte(cPerg,.T. ) } } ) 
AADD(aButtons, { 1,.T.,{|o| nOpca := 1,If(cgpr14Ok(),FechaBatch(),nOpca:=0) }} )
AADD(aButtons, { 2,.T.,{|o| FechaBatch() }} )

FormBatch( cCadastro, aSays, aButtons )

If nOpca == 1                      
	Processa({|lEnd| GPMProcessa()},"Gerando...")
EndIf

Return   
 
/*==================================================================================================
  Relatorio de ressarcimento de despesas 
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */
Static Function GPMProcessa()	

//Local cQuery		:= ""
Local _aArea        := GetArea()
Local nX, nL, nCnta

Private cxFil 		:= cxTrcFil:= ""
Private cxMat 		:= cxTrcRA := ""
Private cxCC  		:= cxTrcCC := ""
Private cSitua		:= ""
Private cAxSitua	:= ""
Private cAxGrp		:= ""
Private cNxtGrp     := ""  
 
Private aConven     := {} 
Private aGrupos     := {}
Private aGrupos2    := {}
Private aDeAtGrp    := {}
Private aArrayX     := {}
Private aTotais     := {}
Private aTotaisG    := {}
Private axClone     := {}

Private lRet        := .F.
Private lAgrupa     := .F.
Private lDeAte      := .F.

Private nTotal      := 0        
Private nColun      := 0 
Private nxSubTot	:= 0
Private nxDifTot	:= 0 
Private nxTotal 	:= 0

Private cMV_PAR01   := MV_PAR01
Private cMV_PAR02   := MV_PAR02
Private _TpArqSaida := MV_PAR04  
Private nDescon		:= 0 //MV_PAR05
Private nAcresc		:= 0 //MV_PAR06	
Private _ExcelLTp2  := .f.      // variavel para impressao do excel agrupado
Private cDemDesde 	:= anomes(MonthSub(stod(MV_PAR02+"01"),nRetroage)) 

Private cIds13oP    := ""
Private cIds13oN    := ""

Private cIdsFerP	:= ""
Private cIdsTerc	:= ""
Private cIdsFerN	:= ""
Private cIdsTerB	:= ""
Private cxDiret     := alltrim(MV_PAR09) //oreport:cdir // diretorio onde usuario selecionou a gravacao.
Private c_xCC_      := ""
Private c_xConv     := ""
Private lYes        := .f.
Private aMO         := {}
Private aSit        := {}
Private aMuni		:= {}
Private lTxtSoe		:= .F.

Private cTxtDeb     := ''
Private cTxtCre     := ''

Private aaAGrp      := {}
Private cxDespCod   := ''

	//Se preenchido valor de desconto
	If !empty(MV_PAR05)
		While .t.
			cTxtDeb := U_fGetAux("Informe o texto para o Desconto:",200,'',100,1200)
			If cTxtDeb == '@'
				Return
			ElseIf empty(cTxtDeb) .or. len(alltrim(cTxtDeb)) > 200
				MsgAlert("O tamanho do texto deverá estar entre 1 e 200 caracteres."+CRLF+"Tamanho atual é "+cValToChar(len(alltrim(cTxtDeb))))
			Else
			 	Exit
			Endif
		EndDo
	EndIf

	//Se preenchido valor de acrescimo
	If !empty(MV_PAR06)
		While .t.
			cTxtCre := U_fGetAux("Informe o texto para o Acréscimo:",200,'',100,1200)
			If cTxtCre == '@'
				Return
			ElseIf empty(cTxtCre) .or. len(alltrim(cTxtCre)) > 200
				MsgAlert("O tamanho do texto deverá estar entre 1 e 200 caracteres."+CRLF+"Tamanho atual é "+cValToChar(len(alltrim(cTxtCre))))
			Else
			 	Exit
			Endif
		EndDo
	EndIf

	If empty(MV_PAR10)
		If !MsgNoYes("A mão de obra está em branco. Deseja realmente processar para todos os tipos de mão de obra ?")
			Return
		EndIf
	EndIf

	nHdlLog := MsfCreate(cxDiret+"Log_"+dtos(date())+StrTran(TIME(),":","")+".TXT",0)

	//cWTabAlias  := "XRESS_"+dtos(date())+StrTran(TIME(),":","")

	SRD->(dbsetorder(1))
	
	//transforma os pergunte range em query 
	MakeSqlExpr(cPerg)  
	
	cxCC    := IIf(Empty( mv_par01), "RA_CC     >= 'C"+SPACE(nTamSet -1)+"' AND RA_CC     <= 'C"+Replic("Z",nTamSet-1)+"'", mv_par01)
		
	cxTrcRA := Strtran(cxMat,"RA","RD") 
	cxTrcCC	:= Strtran(cxCC ,"RA","RD")
	cxTrcFil:= Strtran(cxFil,"RA","RD")

	//Gera parametros iniciais no Log
	
	aadd(aLog,"Parâmetros utilizados:")	    				  
	aadd(aLog,padr("  Convenente (C.Custo): ",24)+cMV_PAR01)	    				  
	aadd(aLog,padr("  Periodo AAAAMM: "      ,24)+ MV_PAR02)	    				  
	aadd(aLog,padr("  Agrupamento: "         ,24)+ MV_PAR03)	    				  
	aadd(aLog,padr("  Valor de Desconto : "  ,24)+ Transform(MV_PAR05, '@E 999,999.99'))	    				  
	aadd(aLog,padr("  Valor de Acréscimo: "  ,24)+ Transform(MV_PAR06, '@E 999,999.99'))	    				  
	aadd(aLog,padr("  Antecipado/Normal : "  ,24)+ if(MV_PAR07==1,'Antecipado','Normal'))    				  
	aadd(aLog,padr("  Dia da Antecipação: "  ,24)+ MV_PAR08)	    				  
	aadd(aLog,padr("  Mão de Obra:        "  ,24)+ MV_PAR10)	    				  
	
	aadd(aLog,"")
	aadd(aLog,"Hora inicial: "+time())
	aadd(aLog,"")	    				  
	For nL := 1 to len(aLog)
		fWrite(nHdlLog, aLog[nL] + CRLF)
	Next nL      
	
    // caso seja selecionado a opcao "html/excel detalhado" imprimira as verbas ao inves dos grupos.
	If _TpArqSaida = 2
		//monta o array aconven para impressao em excel
		aConven:= aclone(fExcConv(aArrayX)) 
		Processa({|lEnd| fResExcl()	},"Gerando a planilha...")

    //qdo usuario selecionar o parametro de agrupamento
	ElseIf !Empty(MV_PAR03) 
	        
			//monta o array aconven para impressao agrupado
			aConven:= aclone(U_fxAgrupa(MV_PAR03,if(MV_PAR07==1,"A","N"))) 
			
			aSort(aConven,,,{|x,y| x[4] < y[4]})				
	
	    	// verifico se extrapola a impressao na A4, no caso estou limitando a impressao de 22 grupos 			
			lRet:= U_fxGrupo() 
		    If lRet .And. _TpArqSaida = 5
				// carrega arrays
				fxCArrays(aMO,aSit,aMuni)
				lAgrupa:= lYes:= .t.
				u_fxMonExc("",MV_PAR03,1,MV_PAR02)   // estou enviando sempre 1 na 3ª pos, pois o aconv será unico qdo agrupado	
			Else
		        //variavel para identificar que existe agrupamento utilizada na rotina CGPER21.PRW
		    	lAgrupa:= .t.
		    	u_CGPER21("CGPER21",MV_PAR03,1)				
			Endif
	
	//Processa arquivo txt do SOE
	ElseIf _TpArqSaida = 4

		lTxtSoe:= .T.
		
		aDirect:= Directory(cxDiret+"*.txt")
		FOR nCnta:= 1 to Len(aDirect)
			FERASE(cxDiret + aDirect[nCnta][1])
		Next			

		// carrega arrays
		fxCArrays(aMO,aSit,aMuni)	
		
		/*
		//Processa arquivo txt com agrupamento
		*/
		
		//array que recebe todos os agrupamentos ( ex: ITAU, BRADESCO, ETC)
		aDeAtGrp:= aclone(U_fConvAgrp(aArrayX,"S",if(MV_PAR07==1,"A","N")))
		lYes:= .t.		
		If len(aDeAtGrp) > 0
			For nx :=1 to len(aDeAtGrp)
				//busco todos os convenentes que estao dentro do agrupamento.	
				aConven:= aclone(U_fxAgrupa(aDeAtGrp[nx,1],if(MV_PAR07==1,"A","N")))  
				
				aSort(aConven,,,{|x,y| x[4] < y[4]})										
				
    			// verifico se extrapola a impressao na A4, no caso estou limitando a impressao de 22 grupos 			
				lRet:= U_fxGrupo2() 			                                 
			    If lRet .And. Len(aConven) > 0
			    	// seto .t. para utilizar a funcao de agrupamento utilizada na rotina CGPER21.PRW
			    	lAgrupa:= .t.
					u_fxMonExc("",aDeAtGrp[nx,1],1,MV_PAR02)   // estou enviando sempre 1 na 3ª pos, pois o aconv será unico qdo agrupado
				Endif		
				//reinicializa a variavel para proximos registros	
				lAgrupa:= .f.			
			Next nx	
		Endif

		/*
		//Processa arquivo txt sem agrupamento
		*/
		aclone := aConven:= {}
		//array que recebe apenas os convenentes de-ate desprezandos os que possuem agrupamento
		axClone:= aclone(U_fConvAgrp(,"N",if(MV_PAR07==1,"A","N"))) 
		
		nxClone1:= len(axClone) 
		nxClonCT:= 0
					
		//trata o array separando por convenente e layouts diferentes
		For nx :=1 to len(axClone)                          

			nxClonCT++
			
			IncProc( "Atualizando registros " + cvaltochar(nxClonCT) + " de " + cvaltochar(nxClone1) )			  						
			
		    c_xConv:= axClone[nx,1]
		    c_xCC_ := axClone[nx,4]  // sera usado no IN da query 
		    nPos   := 0                                         
			If !(nPos := Ascan(aConven,{|x| x[1] == c_xConv .And. left(x[4],5) == left(c_xCC_,5) })) > 0
				aAdd( aConven, { axClone[nx,1], axClone[nx,2], axClone[nx,3], axClone[nx,4], axClone[nx,5], "" ,axClone[nx,4] } )	
			Else /*atualiza os dados do convenente ja encontrado
				 aConven[nPos,1]:= axClone[nPos,1]
				 aConven[nPos,2]:= axClone[nPos,2]
				 aConven[nPos,3]:= axClone[nPos,3]
				 aConven[nPos,4]:= axClone[nPos,4]
				 aConven[nPos,5]:= axClone[nPos,5]
				 */
				 aConven[nPos,7]+= c_xCC_
			Endif    
	
		Next nx	       
        
		lYes:= .f.
		
		// verifico se extrapola a impressao na A4, no caso estou limitando a impressao de 22 grupos 						
		If len(aConven) > 0 .And. (lRet:= U_fxGrupo2())    
		
			 aSort(aConven,,,{|x,y| x[4] < y[4]})
			 
             // gera um relatorio para o mesmo convenente
		     For nx:=1 to Len(aConven)
			    	// seto .f. para utilizar a funcao de de-ate utilizada na rotina CGPER21.PRW
   			    	lDeAte:= .t.    
   			    	u_fxMonExc("","",nx,MV_PAR02)
			 Next nx
		Endif 
		
		nHdSOE := MsfCreate(cxDiret+"AE_ARH_"+RIGHT(TRIM(MV_PAR02),2)+LEFT(TRIM(MV_PAR02),4)+".txt",0)
		
		aDirect:= Directory(cxDiret+"*.txt")
		FOR nCnta:= 1 to Len(aDirect)            
			IF !("AE_ARH_"$UPPER(aDirect[nCnta][1]) .OR. "LOG_"$UPPER(aDirect[nCnta][1]))
				oFile:= FWFileReader():new(cxDiret + aDirect[nCnta][1])
				 
				If oFile:Open()
					Do While oFile:Hasline()
						fWrite(nHdSOE, oFile:GetLine() + CRLF)
					End Do
				EndIF     
				
				oFile:Close()
				
				FERASE(cxDiret + aDirect[nCnta][1])
			EndIF		
		Next	
		
		FClose(nHdSOE)
					
	//qdo usuario selecionar o parametro de-ate, deve-se imprimir todos os convenentes + os que possuem agrupamento, no novo formato em excel 
	ElseIf _TpArqSaida = 5	 
			
			// carrega arrays
			fxCArrays(aMO,aSit,aMuni)	
		    
			If MsgYesNo("SIM - Executar apenas os convenentes COM agrupamento" + CRLF + CRLF +;
		                "NAO - Executar apenas os convenentes SEM agrupamento. ")       
			
				//array que recebe todos os agrupamentos ( ex: ITAU, BRADESCO, ETC)
				aDeAtGrp:= aclone(U_fConvAgrp(aArrayX,"S",if(MV_PAR07==1,"A","N")))
				lYes:= .t.		
				If len(aDeAtGrp) > 0
					For nx :=1 to len(aDeAtGrp)
						//busco todos os convenentes que estao dentro do agrupamento.	
						aConven:= aclone(U_fxAgrupa(aDeAtGrp[nx,1],if(MV_PAR07==1,"A","N")))  
						
						aSort(aConven,,,{|x,y| x[4] < y[4]})										
						
		    			// verifico se extrapola a impressao na A4, no caso estou limitando a impressao de 22 grupos 			
						lRet:= U_fxGrupo2() 			                                 
					    If lRet .And. Len(aConven) > 0
					    	// seto .t. para utilizar a funcao de agrupamento utilizada na rotina CGPER21.PRW
					    	lAgrupa:= .t.
							u_fxMonExc("",aDeAtGrp[nx,1],1,MV_PAR02)   // estou enviando sempre 1 na 3ª pos, pois o aconv será unico qdo agrupado
						Endif		
						//reinicializa a variavel para proximos registros	
						lAgrupa:= .f.			
					Next nx	
				Endif          
		    Else     
		    
				If MsgYesNo("SIM - Imprimir Geral incluido Banco do Brasil e CEF (demandara mais tempo) " + CRLF + CRLF +;
		                    "NAO - Imprimir Geral desprezando Banco do Brasil e CEF.  ")	 
		             cxDespCod := ""
		             lxImpGera := .t.
		        Else
		             cxDespCod := "0001/0033"
		             lxImpGera := .f.
		        Endif			    
			    
				aclone := aConven:= {}
				//array que recebe apenas os convenentes de-ate desprezandos os que possuem agrupamento
				axClone:= aclone(U_fConvAgrp(,"N",if(MV_PAR07==1,"A","N"))) 
				
				nxClone1:= len(axClone) 
				nxClonCT:= 0
							
				//trata o array separando por convenente e layouts diferentes
				For nx :=1 to len(axClone)                          
		
					nxClonCT++
					
					IncProc( "Atualizando registros " + cvaltochar(nxClonCT) + " de " + cvaltochar(nxClone1) )			  						
					
				    c_xConv:= axClone[nx,1]
				    c_xCC_ := axClone[nx,4]  // sera usado no IN da query 
				    nPos   := 0                                         
					If !(nPos := Ascan(aConven,{|x| x[1] == c_xConv .And. left(x[4],5) == left(c_xCC_,5) })) > 0
						aAdd( aConven, { axClone[nx,1], axClone[nx,2], axClone[nx,3], axClone[nx,4], axClone[nx,5], "" ,axClone[nx,4] } )	
					Else /*atualiza os dados do convenente ja encontrado
						 aConven[nPos,1]:= axClone[nPos,1]
						 aConven[nPos,2]:= axClone[nPos,2]
						 aConven[nPos,3]:= axClone[nPos,3]
						 aConven[nPos,4]:= axClone[nPos,4]
						 aConven[nPos,5]:= axClone[nPos,5]
						 */
						 aConven[nPos,7]+= c_xCC_
					Endif    
			
				Next nx	       
	            
				lYes:= .f.
				
	  			// verifico se extrapola a impressao na A4, no caso estou limitando a impressao de 22 grupos 						
				If len(aConven) > 0 .And. (lRet:= U_fxGrupo2())    
				
					 aSort(aConven,,,{|x,y| x[4] < y[4]})
					 
	                 // gera um relatorio para o mesmo convenente
				     For nx:=1 to Len(aConven)
					    	// seto .f. para utilizar a funcao de de-ate utilizada na rotina CGPER21.PRW
		   			    	lDeAte:= .t.
		   			    	If lxImpGera       
			   			    	u_fxMonExc("","",nx,MV_PAR02)
			   			    ElseIf !(Substr(aConven[nx,4],2,4) $ cxDespCod)
								u_fxMonExc("","",nx,MV_PAR02)			   			    
			   			    Endif	

					 Next nx
				Endif 
            
			Endif
	//qdo usuario selecionar o parametro de-ate, deve-se imprimir todos os convenentes + os que possuem agrupamento (PDF)
	Else	
		
		If MsgYesNo("SIM - Executar apenas os convenentes COM agrupamento" + CRLF + CRLF +;
		            "NAO - Executar apenas os convenentes SEM agrupamento. ")
			//array que recebe todos os agrupamentos ( ex: ITAU, BRADESCO, ETC)
			aDeAtGrp:= aclone(U_fConvAgrp(aArrayX,"S",if(MV_PAR07==1,"A","N")))
			lYes:= .t.		
			If len(aDeAtGrp) > 0
				For nx :=1 to len(aDeAtGrp)
					//busco todos os convenentes que estao dentro do agrupamento.	
					aConven:= aclone(U_fxAgrupa(aDeAtGrp[nx,1],if(MV_PAR07==1,"A","N")))      
					
					aSort(aConven,,,{|x,y| x[4] < y[4]})				
					
	    			// verifico se extrapola a impressao na A4, no caso estou limitando a impressao de 22 grupos 			
					lRet:= U_fxGrupo2() 			                                 
				    If lRet .And. Len(aConven) > 0
				    	// seto .t. para utilizar a funcao de agrupamento utilizada na rotina CGPER21.PRW
				    	lAgrupa:= .t.
						u_CGPER21("CGPER21",aDeAtGrp[nx,1],1)   // estou enviando sempre 1 na 3ª pos, pois o aconv será unico qdo agrupado
					Endif		
					//reinicializa a variavel para proximos registros	
					lAgrupa:= .f.			
				Next nx	
			Endif          
		
		Else   
		
			If MsgYesNo("SIM - Imprimir Geral incluido Banco do Brasil e CEF (demandara mais tempo) " + CRLF + CRLF +;
	                    "NAO - Imprimir Geral desprezando Banco do Brasil e CEF.  ")	 
	             cxDespCod := ""
	             lxImpGera := .t.
	        Else
	             cxDespCod := "0001/0033"
	             lxImpGera := .f.
	        Endif				       
	        
			//array que recebe apenas os convenentes de-ate desprezandos os que possuem agrupamento
			axClone:= aclone(U_fConvAgrp(,"N",if(MV_PAR07==1,"A","N"))) 
			
			nxClone1:= len(axClone) 
			nxClonCT:= 0
						
			//trata o array separando por convenente e layouts diferentes
			For nx :=1 to len(axClone)                          
	
				nxClonCT++
				
				IncProc( "Atualizando registros " + cvaltochar(nxClonCT) + " de " + cvaltochar(nxClone1) )			  						
				
			    c_xConv:= axClone[nx,1]
			    c_xCC_ := axClone[nx,4]  // sera usado no IN da query 
			    nPos   := 0                                         
				If !(nPos := Ascan(aConven,{|x| x[1] == c_xConv .And. left(x[4],5) == left(c_xCC_,5) })) > 0
					aAdd( aConven, { axClone[nx,1], axClone[nx,2], axClone[nx,3], axClone[nx,4], axClone[nx,5], "" ,axClone[nx,4] } )	
				Else /*atualiza os dados do convenente ja encontrado
					 aConven[nPos,1]:= axClone[nPos,1]
					 aConven[nPos,2]:= axClone[nPos,2]
					 aConven[nPos,3]:= axClone[nPos,3]
					 aConven[nPos,4]:= axClone[nPos,4]
					 aConven[nPos,5]:= axClone[nPos,5]
					 */
					 aConven[nPos,7]+= c_xCC_
				Endif    
		
			Next nx	   
  			// verifico se extrapola a impressao na A4, no caso estou limitando a impressao de 22 grupos 						
			If len(aConven) > 0 .And. (lRet:= U_fxGrupo2()) 
				 
				 aSort(aConven,,,{|x,y| x[4] < y[4]})				
                 
                 // gera um relatorio para o mesmo convenente
			     For nx:=1 to Len(aConven)
				    	// seto .f. para utilizar a funcao de de-ate utilizada na rotina CGPER21.PRW
	   			    	lDeAte:= .t.
	   			    	If lxImpGera       
							u_CGPER21("CGPER21",,nx)
		   			    ElseIf !(Substr(aConven[nx,4],2,4) $ cxDespCod)
							u_CGPER21("CGPER21",,nx)
		   			    Endif						
		   			    
				 Next nx
			Endif 

		EndIf
		
	Endif

	If _TpArqSaida <> 2 //Quando PDF ou Excel conforme layout
		nTotFunc := nTotValLog := 0
		aEval( aTotais ,{ |x| nTotFunc   += x[3]  } )
		aEval( aTotais ,{ |x| nTotValLog += (x[4]+x[5]-x[6])  } )
//		nTotValLog += (nAcresc-nDescon)
		aadd(aLog,"   "+replicate('-',153))	 
		fWrite(nHdlLog, aLog[len(aLog)] + CRLF)
		aadd(aLog,"   Quantidade de arquivos gerados: "+strzero(len(aTotais),4)+space(83)+"Func: "+strzero(nTotFunc,5)+"   Valor: "+Transform(nTotValLog, '@E 99,999,999.99')) 
		fWrite(nHdlLog, aLog[len(aLog)] + CRLF)
	EndIf
	
	aadd(aLog,"")	    				  
	fWrite(nHdlLog, aLog[len(aLog)] + CRLF)
	aadd(aLog,"Hora final:   "+time())	    				  
	fWrite(nHdlLog, aLog[len(aLog)] + CRLF)
	
	If _TpArqSaida == 2 // html/excel detalhado
		fMakeLog({aLog},{"Planilha gerada:"},,,"Log_planilha_"+mv_par02,"Planilha de Conferência de Ressarcimento","G","L",,.F.) //"Log de ocorrencias
	ElseIf _TpArqSaida == 3 .or. _TpArqSaida == 5// excel conforme layout
		fMakeLog({aLog},{"Arquivos XLS gerados:"},,,"Log_XLSs_"+mv_par02,"Relatórios de Ressarcimento","G","L",,.F.) //"Log de ocorrencias
	Else
		fMakeLog({aLog},{"Arquivos PDF gerados:"},,,"Log_PDFs_"+mv_par02,"Relatórios de Ressarcimento","G","L",,.F.) //"Log de ocorrencias
	EndIf	
	RestArea (_aArea)
	If cWTabAlias != Nil
		If SELECT(cWTabAlias) > 0
			(cWTabAlias)->( dbclosearea() )
		Endif
		tcDelFile(cWTabAlias)
	EndIf
	FClose(nHdlLog)

Return

/*==================================================================================================
  Perguntas do sistema
@author     Totvs
@since      
@param
@version    P12
@return
@project
@client    Ciee 
Obs		   Alteração DAC - Denilso Incluindo 4-Layout SOE	
//================================================================================================== */
Static Function fChkPerg()
Local aRegs:={}
Local j
Local i

dbSelectArea("SX1")
SX1->(dbSetOrder(1))
//			1		2		3							4							5							6		7	8		9		10		11	12																13			14					15				16				17			18	19						20							21						22		23		24					25						26						27		28	29	30					
Aadd(aRegs,{cPerg, "01"  ,"Convenente (C.Custo) ?"   ,"Convenente (C.Custo) ?"   ,"Convenente (C.Custo) ?" 	  ,"MV_CH1","C" ,99     ,0      ,0     ,"R",""          													,"mv_par01","              "   ,""     		  ,""     		 ,"RA_CC"     ,""   ,"             "  		 ,""        			  ,""        				,""     ,""   ,""     				,""     				,""     				,""   ,""   ,""   			  	,""     		,""     		,""   ,""   ,""   ,""     ,""     ,""   ,"CTT"		,"S" ,""     ,".RHCCUSTO.",""})
aAdd(aRegs,{cPerg, '02'  ,'Periodo AAAAMM ?'		 ,'Periodo AAAAMM ?'    	 ,'Periodo AAAAMM  ?'  	  	  ,'MV_CH2','C' , 6     ,0      ,0     ,'G','naovazio()'													,'mv_par02',"              "   ,""        	  ,""     		 ,""   		  ,""   ,"             "         ,""        			  ,""        				,""     ,""   ,""     				,""     				,""     				,""   ,""   ,""   			  	,""     		,""     		,""   ,""   ,""   ,""     ,""     ,""   ,""   		,"S" ,""     ,"",""})
aAdd(aRegs,{cPerg, '03'  ,'Agrupamento ?'  			 ,'Agrupamento   ?'     	 ,'Agrupamento    ?'   	  	  ,'MV_CH3','C' , 15    ,0      ,0     ,'G','         ' 													,'MV_PAR03',"              "   ,""     		  ,""     		 ,""   		  ,""   ,"             "  		 ,""        			  ,""        				,""     ,""   ,""     				,""     				,""     				,""   ,""   ,""               	,""     		,""     		,""   ,""   ,""   ,""     ,""     ,""   ,"U001"		,"S" ,""     ,"",""})
aAdd(aRegs,{cPerg, '04'  ,'Formato de saída ?'	     ,'Formato de saída ?'   	 ,'Formato de saída'   	  	  ,'MV_CH4','C' ,1      ,0      ,0     ,'C',''          													,'MV_PAR04',"1-PDF"            ,"1-PDF"		  ,"1-PDF"		 ,""          ,""   ,"2-Html Detalhad"		 ,"2-Html Detalhad"		  ,"2-Html Detalhad"		,""		,""   ,"3-Excel layout "	,"3-Excel layout "		,"3-Excel layout "		,""   ,""   ,"4-Layout SOE"   	,"4-Layout SOE" ,"4-Layout SOE" ,""   ,""   ,"5-Novo Excel"   ,"5-Novo Excel"     ,"5-Novo Excel"     ,""   ,""  			,"S" ,""     ,"",""})
aAdd(aRegs,{cPerg, '05'  ,'Valor de Desconto ?' 	 ,'Valor de Desconto '  	 ,'Valor de Desconto '        ,'MV_CH5','N' ,14     ,2      ,0     ,'G','' 															    ,'MV_PAR05',"              "   ,""     		  ,""     		 ,""   	   	  ,""   ,"             "  		 ,""        			  ,""        				,""     ,""   ,""     				,""     				,""     				,""   ,""   ,""   				,""     		,""     		,""   ,""   ,""   ,""     ,""     ,""   ,""   		,"S" ,""     ,"",""})
aAdd(aRegs,{cPerg, '06'  ,'Valor de Acréscimo ?' 	 ,'Valor de Acréscimo'  	 ,'Valor de Acréscimo'     	  ,'MV_CH6','N' ,14     ,2      ,0     ,'G',''          	    											,'MV_PAR06',"              "   ,""            ,""     		 ,""   		  ,""   ,"             "  		 ,""        			  ,""        				,""     ,""   ,""     				,""     				,""     				,""   ,""   ,""   				,""     		,""     		,""   ,""   ,""   ,""     ,""     ,""   ,""   		,"S" ,""     ,"",""})
aAdd(aRegs,{cPerg, '07'  ,'Antecipado/Normal ?' 	 ,'Antecipado/Normal ?' 	 ,'Antecipado/Normal ?'  	  ,'MV_CH7','C' ,1      ,0      ,0     ,'C',''          													,'MV_PAR07',"1-Antecipado  "   ,"1-Antecipado","1-Antecipado",""          ,""   ,"2-Normal"       		 ,"2-Normal"			  ,"2-Normal"				,""		,""   ,""     				,""     				,""     				,""   ,""   ,""   				,""     		,""     		,""   ,""   ,""   ,""     ,""     ,""   ,""  			,"S" ,""     ,"",""})
Aadd(aRegs,{cPerg, "08"  ,"Dia da Antecipação ?"	 ,"Dia da Antecipação ?"	 ,"Dia da Antecipação ?"  	  ,"MV_CH8","C" , 2     ,0      ,0     ,"G","if(MV_PAR07==2,vazio(),val(MV_PAR08)>0.and.val(MV_PAR08)<31)"  ,"MV_PAR08","              "   ,""     		  ,""     		 ,""          ,""   ,"             "  		 ,""        			  ,""        				,""     ,""   ,""     				,""     				,""     				,""   ,""   ,""   				,""     		,""     		,""   ,""   ,""   ,""     ,""     ,""   ,""	        ,"S" ,""     ,"","99"})
Aadd(aRegs,{cPerg, "09"  ,"Diretório para Gravação ?","Diretório para Gravação ?","Diretório para Gravação ?" ,"MV_CH9","C" ,99     ,0      ,0     ,"G","GetDire() .and. naovazio()"								    ,"MV_PAR09","              "   ,""     		  ,""     		 ,""          ,""   ,"             "  		 ,""        			  ,""        				,""     ,""   ,""     				,""     				,""     				,""   ,""   ,""   				,""     		,""     		,""   ,""   ,""   ,""     ,""     ,""   ,""	        ,"S" ,""     ,"",""})
aAdd(aRegs,{cPerg, '10'  ,'Mao de Obra ?'  			 ,'Mao de Obra ?'     	     ,'Mao de Obra ?'   	  	  ,'MV_CHA','C' , 02    ,0      ,0     ,'G','Vazio() .or. EXISTCPO("SX5","_0"+&(READVAR()))         ' 		,'MV_PAR10',"              "   ,""     		  ,""     		 ,""   		  ,""   ,"             "  		 ,""        			  ,""        				,""     ,""   ,""     				,""     				,""     				,""   ,""   ,""               	,""     		,""     		,""   ,""   ,""   ,""     ,""     ,""   ,"_0"		,"S" ,""     ,"",""})

For i:=1 to Len(aRegs)
	If !SX1->(dbSeek(cPerg +aRegs[i,2]))  
		RecLock("SX1",.T.)
		For j:=1 to SX1->(FCount())
			If j<= Len(aRegs[i])
				SX1->(FieldPut(j,aRegs[i,j]))
			Endif
		Next
		SX1->(MsUnlock())
	//localizou verificar se esta atualizado se não atualizar	
	ElseIf ( i==4  .and. Empty(SX1->X1_DEF04) .and. !Empty(aRegs[i,29]))
		RecLock("SX1",.F.)
		For j:=1 to SX1->(FCount())
			If j<= Len(aRegs[i])
				SX1->(FieldPut(j,aRegs[i,j]))
			Endif
		Next
		SX1->(MsUnlock())

	Endif
Next
Return Nil  


/*==================================================================================================
  Gera relatorio em excel onde imprimira todas as verbas detalhadas conforme o grupo vinculado.
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */ 
Static Function fResExcl()

//Local cExtens	 := ""
Local _cArqTmp   := cxDiret+"ressarc_excel_"+mv_par02+".html" 
Local nz, nCount, nDet
Local aBkpDds 	 := {}

Private lProvisao13:= .f.
Private lProvisaoFe:= .f.
Private lAchouSub
Private axPdExc    := {}
		
		//Se ja existe o arquivo destino com o mesmo nome 
		If File(_cArqTmp)

			//Deleta o arquivo anterior
			If !(fErase(_cArqTmp) == 0)
				cMsg := '   Ocorreram problemas na tentativa de deleção do arquivo '+AllTrim(_cArqTmp)+'.'
				MsgStop(cMsg)
				aadd(aLog,cMsg)
				fWrite(nHdlLog, aLog[len(aLog)] + CRLF)
				Return
			EndIf

		EndIf

		//Busca descricoes dos tipos de mao de obra
		aMO := {}
		If SX5->(dbseek(xFilial("SX5")+"_0"))
			While SX5->(!eof()) .and. SX5->X5_TABELA=='_0'
				aadd(aMO,{alltrim(SX5->X5_CHAVE),alltrim(SX5->X5_DESCRI)})
				SX5->(dbskip())
			EndDo
		EndIf
		
		//Busca descricoes de situacoes
		aSit := {}
		If SX5->(dbseek(xFilial("SX5")+"31"))
			While SX5->(!eof()) .and. SX5->X5_TABELA=='31'
				aadd(aSit,{alltrim(SX5->X5_CHAVE),alltrim(SX5->X5_DESCRI)})
				SX5->(dbskip())
			EndDo
		EndIf

		nHandle := MsfCreate(_cArqTmp,0) 
		
		// controle da coluna subtotal
		lAchouSub:= .F. 		
		
		// preparando para montar o cabecalho conforme as verbas que encontrar.
		_resultado := '<html>' + CRLF 
		_resultado += '<meta http-equiv=Content-Type content="text/html; charset=windows-1252">' + CRLF 
		_resultado += '<body>' + CRLF 
		_resultado += '<table cellspacing=0 cellpadding=0  border="1">' + CRLF 
		_resultado += '<tr>'         
		_resultado += '<td colspan="13" bgcolor="#903c90" align="center" valign="center"><font face="Calibri" size="3" color="#ffffff"><b>CONFERENCIA DE RESSARCIMENTO DE DESPESAS - Mes/Ano Base: '+Substr(MV_PAR02,5,2)+'/'+Substr(MV_PAR02,1,4)+' </td>'
		_resultado += '</tr>'        
		_resultado += '<tr>'         		 		
		_resultado += '<td bgcolor="#00c9e0" align="center" valign="center"><font face="Calibri" size="2" color="#ffffff"><b>&#8203 CNPJ	 		</td>'
		_resultado += '<td bgcolor="#00c9e0" align="center" valign="center"><font face="Calibri" size="2" color="#ffffff"><b>&#8203 REGIONAL 		</td>'		
		_resultado += '<td bgcolor="#00c9e0" align="center" valign="center"><font face="Calibri" size="2" color="#ffffff"><b>&#8203 CENTRO CUSTO  	</td>'
		_resultado += '<td bgcolor="#00c9e0" align="center" valign="center"><font face="Calibri" size="2" color="#ffffff"><b>&#8203 DESC C. CUSTO	</td>'
		_resultado += '<td bgcolor="#00c9e0" align="center" valign="center"><font face="Calibri" size="2" color="#ffffff"><b>&#8203 MATRICULA		</td>' 
		_resultado += '<td bgcolor="#00c9e0" align="center" valign="center"><font face="Calibri" size="2" color="#ffffff"><b>&#8203 NOME       	    </td>'
		_resultado += '<td bgcolor="#00c9e0" align="center" valign="center"><font face="Calibri" size="2" color="#ffffff"><b>&#8203 ADMISSAO		</td>' 		
		_resultado += '<td bgcolor="#00c9e0" align="center" valign="center"><font face="Calibri" size="2" color="#ffffff"><b>&#8203 SALARIO 		</td>' 		
		_resultado += '<td bgcolor="#00c9e0" align="center" valign="center"><font face="Calibri" size="2" color="#ffffff"><b>&#8203 CARGA HORARIA	</td>' 		
		_resultado += '<td bgcolor="#00c9e0" align="center" valign="center"><font face="Calibri" size="2" color="#ffffff"><b>&#8203 SITUACAO em '+right(mv_par02,2)+'/'+left(mv_par02,4)+'</td>' 		
		_resultado += '<td bgcolor="#00c9e0" align="center" valign="center"><font face="Calibri" size="2" color="#ffffff"><b>&#8203 ID. MO 	     	</td>' 		
		_resultado += '<td bgcolor="#00c9e0" align="center" valign="center"><font face="Calibri" size="2" color="#ffffff"><b>&#8203 MAO DE OBRA	    </td>' 		
		_resultado += '<td bgcolor="#00c9e0" align="center" valign="center"><font face="Calibri" size="2" color="#ffffff"><b>&#8203 RESCISAO 		</td>' 		
						
        If Len(aConven) = 0
		   MsgAlert("Nao foi encontrado convenente com a parametrizacao correta, favor verificar.")
		   Return        	
        Endif
        
	    // seleciona as verbas que serao impressas, caso o usuario preencha varios convenentes imprimo todas as verbas para todos os grupos vinculados.
	    cQuery := " SELECT DISTINCT(RV_COD) AS CODIGO, SUBSTRING(RV_DESC,1,12) AS DESCR, RV_TIPOCOD, 'C'+RV_COD AS CODPD, "
	    cQuery +=        " RV_DESC AS DESCRCOMPL, RV_REFFER, RV_REF13 "
	    cQuery += " FROM " + RetSqlName("SRV") + " SRV "
		cQuery += " WHERE SRV.D_E_L_E_T_ = ' ' AND ( " 
		/*
		For nx:= 1 to len(aConven)
        	// retira a ultima virgula do campo devido a rotina gravar uma "," na tabela      
			cAxGrp += StrTran(Alltrim(Substr(aConven[nx,2],1,len(alltrim(aConven[nx,2]))-1)),",","")
		Next
		*/ 		 
		For nz:=1 to len(aaAGrp) //step 3 
			cAxGrp:= aaAGrp[nz,1]
			If Substr(cAxGrp,nz,1) <> "S"
				
				If Substr(cAxGrp,1,3) == "P13"
					lProvisao13:= .T.
					Loop
				Endif
				If Substr(cAxGrp,1,3) == "PFE"
					lProvisaoFe:= .T.				
					Loop
				Endif
				
				If nz == 1
					cQuery += "  RV_XGRUPO LIKE '%"+Substr(cAxGrp,1,3)+"%' " 	  
				Else
					cQuery += "  OR RV_XGRUPO LIKE '%"+Substr(cAxGrp,1,3)+"%' " 
				Endif	
				nColun+= 1

								
			Else 
				lAchouSub:= .t. 
				cNxtGrp += Substr(cAxGrp,1,3)
			Endif	
		Next
		
		cQuery += " ) "		
		
		If SELECT("TSRV") > 0
			TSRV->( dbclosearea() )
		Endif
	
		TCQUERY cQuery NEW ALIAS "TSRV"  
		
		TSRV->( dbgotop() )	 

		//adiciona as verbas no cabecalho colunando-as antes do SUBTOTAL		
		//qdo eu contrar o grupo que iniciar com "S" quer dizer que será colunado apos o subtotal e antes do total.  
		While TSRV->( !Eof() ) 
		   	//_resultado += '<td bgcolor="#FFFF00" align="center" valign="center"><font face="Calibri" size="2" color="#000000"><b>&#8203 '+TSRV->CODIGO+'	</td>'        						
		   	_resultado += '<td bgcolor="#FFFF00" align="center" valign="center"><font face="Calibri" size="2" color="#000000"><b>&#8203 '+TSRV->CODIGO+"-"+TSRV->DESCR+'	</td>'        								   	
			TSRV->( dbSkip() )	    
		Enddo	
		
		If lProvisao13  
		   	_resultado += '<td bgcolor="#FFFF00" align="center" valign="center"><font face="Calibri" size="2" color="#000000"><b>&#8203 '+"Provisao 13º"+'	</td>'        								   	
		Endif
			
		If lProvisaoFe                           
		   	_resultado += '<td bgcolor="#FFFF00" align="center" valign="center"><font face="Calibri" size="2" color="#000000"><b>&#8203 '+"Provisao Ferias"+'	</td>'        								   	
		Endif     		
		
		// imprime coluna SUBtotal
		If lAchouSub
		   	_resultado += '<td bgcolor="#FFFF00" align="center" valign="center"><font face="Calibri" size="2" color="#000000"><b>&#8203 SUB TOTAL 	</td>'        								
		   	
			// seleciona as verbas que serao impressas apos subtotais.
		    cQuery := " SELECT DISTINCT(RV_COD) AS CODIGO, SUBSTRING(RV_DESC,1,12) AS DESCR, RV_TIPOCOD, 'C'+RV_COD AS CODPD, "
		    cQuery +=        " RV_DESC AS DESCRCOMPL, RV_REFFER, RV_REF13 "
		    cQuery += " FROM " + RetSqlName("SRV") + " SRV "
			cQuery += " WHERE SRV.D_E_L_E_T_ = ' ' AND (" 
			For nz:=1 to len(cNxtGrp) step 3
				If nz == 1
					cQuery += "  RV_XGRUPO LIKE '%"+Substr(cNxtGrp,nz,3)+"%' " 	  
				Else
					cQuery += "  OR RV_XGRUPO LIKE '%"+Substr(cNxtGrp,nz,3)+"%' " 
				Endif	
	
			Next           
			cQuery += " ) "
			
			If SELECT("TSRVS") > 0
				TSRVS->( dbclosearea() )
			Endif		
			
			TCQUERY cQuery NEW ALIAS "TSRVS"  
			
			TSRVS->( dbgotop() )	 
	
			// adiciona as verbas ao cabecalho apos a coluna SUBTOTAL		
			While TSRVS->( !Eof() ) 
			   	_resultado += '<td bgcolor="#FFFF00" align="center" valign="center"><font face="Calibri" size="2" color="#000000"><b>&#8203 '+TSRVS->DESCR+'	</td>'        							   	
				TSRVS->( dbSkip() )	    
			Enddo			

		Endif

        // adiciona a ultima coluna TOTAL
	   	_resultado += '<td bgcolor="#FFFF00" align="center" valign="center"><font face="Calibri" size="2" color="#000000"><b>&#8203 TOTAL	</td>'        						

		fWrite(nHandle, _resultado)      
		
		// fecho o cabecalho			
	   	_resultado += '</tr>' + CRLF			
	   	
	    cQuery := " SELECT CTT_CUSTO AS RA_CC, RA_FILIAL, RA_NOME, RA_MAT, RA_XSETOR, CTT_DESC01,RA_ADMISSA, RA_DEMISSA, RA_SALARIO, RA_HRSMES, RA_SITFOLH, RA_CIC, "
	    cQuery += " ZZC_CNPJ, ZZC_DESCR, ZZC_MO, ZZF_MO, ZZF_DESCR, ZZF_CNPJ, ZZF_UF, ZZF_ENDERE, ZZF_CEP, ZZF_TELEF, ZZF_EMAILR, ZZI_DESCR, ZZD_PCONGE "
	    cQuery += " FROM " + RetSqlName("SRA") + " SRA " 
	    cQuery += " INNER JOIN " + RetSqlName("CTT") + " CTT ON CTT_CUSTO =  "
	    cQuery += "  ( Case when 
	    cQuery += "     (Select RE_CCP  FROM " + RetSqlName("SRE") + " where D_E_L_E_T_ = '' and RE_DATA = (Select max(RE_DATA) FROM "
		cQuery += "     " + RetSqlName("SRE") + " where D_E_L_E_T_ = '' and RE_MATP = RA_MAT and RE_DATA <= '"+MV_PAR02+"') and RE_MATP = RA_MAT) <> '' "
   		cQuery += "    then "
		cQuery += "     (Select RE_CCP  FROM " + RetSqlName("SRE") + "  where D_E_L_E_T_ = '' and RE_DATA = (Select max(RE_DATA) FROM " + RetSqlName("SRE") + " "
		cQuery += "      where D_E_L_E_T_ = '' and RE_MATP = RA_MAT and RE_DATA <= '"+MV_PAR02+"') and RE_MATP = RA_MAT) "
		cQuery += "    else "
	    cQuery += "      RA_CC End "
		cQuery += "  ) AND CTT.D_E_L_E_T_ = '' " 	    
		cQuery += " INNER JOIN " + RetSqlName("ZZC") + " ZZC ON SUBSTRING(CTT_CUSTO,2,4) = ZZC_CODIGO  AND ZZC.D_E_L_E_T_ = ''  "
		cQuery += "    AND (ZZC_DTFIM = '' or left(ZZC_DTFIM,6) >= '"+MV_PAR02+"') "
		If MV_PAR07 == 1 //Antecipados
			cQuery += " and ZZC_FOLANT = '" + MV_PAR08 + "'"
		Else
			cQuery += " and ZZC_FOLANT = ''"
		EndIf
		cQuery += " INNER JOIN " + RetSqlName("ZZD") + " ZZD ON ZZD_CODCON = SUBSTRING(CTT_CUSTO,2,4) AND ZZD_PERINI <= '"+MV_PAR02+"' and (ZZD_PERFIM >= '"+MV_PAR02+"' or ZZD_PERFIM = '')  and ZZD.D_E_L_E_T_ = '' "
		cQuery += " INNER JOIN " + RetSqlName("ZZF") + " ZZF ON 'C'+ZZF_CODCON+ZZF_CODIGO = CTT_CUSTO AND ZZF_PERINI = ZZD_PERINI and ZZF.D_E_L_E_T_ = '' " 
		cQuery += " LEFT OUTER JOIN " + RetSqlName("ZZI") + " ZZI ON ZZI_CODIGO = RA_XSETOR and ZZI.D_E_L_E_T_ = '' "    
		cQuery += " WHERE SRA.D_E_L_E_T_ = ' ' AND "
		cQuery +=       " left(RA_ADMISSA,6) <= '"+MV_PAR02+"' and "
		cQuery +=       " (RA_DEMISSA = '' or left(RA_DEMISSA,6) >= '"+cDemDesde+"') and "
		cQuery += "  " + cxCC + " "														  		  
		cQuery += "	AND SUBSTRING(RA_FILIAL,7,2) = '02' "						
		If !empty(MV_PAR10)
			cQuery += " and (ZZF_MO = '" + MV_PAR10 + "' or (ZZF_MO='' and ZZC_MO = '" + MV_PAR10 + "'))"
		EndIf
		cQuery += " ORDER BY RA_FILIAL, RA_CC, RA_XSETOR, RA_NOME, RA_MAT " 

		If SELECT("TRB") > 0
			TRB->( dbclosearea() )
		Endif
		
		TCQUERY cQuery NEW ALIAS "TRB" 
		COUNT TO nCount	
				
		ProcRegua(nCount)
		
		TRB->(dbgotop())
			
		While TRB->( !Eof() )
		
			IncProc(TRB->RA_FILIAL+" - Conv: "+alltrim(CTT_DESC01)+CRLF+"Nome: "+TRB->RA_NOME)	    				  

			// busca os valores para o funcionario colunando com todas as verbas
			fxValores()
			
			nxSubTot := nxDifTot := nTotLinha:= 0
	
	        /* verifico se o funcionario tem valores a imprimir, basta ter uma verba com valor que sera impresso o registro.		
			aEval( axPdExc ,{ |x| nTotLinha   += x[3]  } )
			If nTotLinha > 0
	    		TRB->( dbSkip() )
	    		Loop
			Endif    
			*/
			                       
	   		// descarrrego os valores conforme colunas
	   		_resultado := '<tr>'  
	   		cxCNPJ     := Transform(TRB->ZZC_CNPJ, '@R 99.999.999/9999-99')
			_resultado += '<td align="center"><font face="Calibri" size="1">'  		   + cxCNPJ		          +											   ' </td>'
			_resultado += '<td align="center"><font face="Calibri" size="1">'  		   + TRB->ZZC_DESCR       +											   ' </td>'			
			_resultado += '<td align="center"><font face="Calibri" size="1">' 		   + TRB->RA_CC           +											   ' </td>'	   		
			_resultado += '<td align="center"><font face="Calibri" size="1">' 		   + TRB->CTT_DESC01      +											   ' </td>'	   		
			_resultado += '<td align="center"><font face="Calibri" size="1">'  		   + TRB->RA_MAT          +											   ' </td>'
			_resultado += '<td align="center"><font face="Calibri" size="1">'  		   + TRB->RA_NOME         +											   ' </td>'
			_resultado += '<td align="center"><font face="Calibri" size="1">&#8203 '   + Substr(TRB->RA_ADMISSA,7,2)+"/"+Substr(TRB->RA_ADMISSA,5,2)+"/"+Substr(TRB->RA_ADMISSA,1,4)+' </td>'
			_resultado += '<td align="center"><font face="Calibri" size="1">&#8203 R$' + Transform(TRB->RA_SALARIO, '@E 99,999,999.99')      +		       ' </td>'			
			_resultado += '<td align="center"><font face="Calibri" size="1">&#8203 '   + Transform(TRB->RA_HRSMES , '@E 999.99')             +			   ' </td>'
			cxSitFol := ''	
			If (nPos := Ascan(aSit,{|x| x[1] == alltrim(TRB->RA_SITFOLH) })) > 0
				cxSitFol := aSit[nPos,2]
			Endif
			_resultado += '<td align="center"><font face="Calibri" size="1">&#8203 '   + cxSitFol             +											   ' </td>'						
			_resultado += '<td align="center"><font face="Calibri" size="1">&#8203 '   + if(!empty(TRB->ZZF_MO),TRB->ZZF_MO,TRB->ZZC_MO)  +											   ' </td>'
			cxMaoObra := ''	
			If (nPos := Ascan(aMO,{|x| x[1] == alltrim( if(!empty(TRB->ZZF_MO),TRB->ZZF_MO,TRB->ZZC_MO) ) })) > 0
				cxMaoObra := aMO[nPos,2]
			Endif
			_resultado += '<td align="center"><font face="Calibri" size="1">'  		   + cxMaoObra            +											   ' </td>'			
			_resultado += '<td align="center"><font face="Calibri" size="1">&#8203 '   + Substr(TRB->RA_DEMISSA,7,2)+"/"+Substr(TRB->RA_DEMISSA,5,2)+"/"+Substr(TRB->RA_DEMISSA,1,4)+' </td>'


            For nDet:= 1 to len(axPdExc)
            
            			lTemValor:= .t.
            
						nValAux := axPdExc[nDet,3]
						
						If axPdExc[nDet,1] == "P13"
						
							_resultado += '<td align="center"><font face="Calibri" size="1"'
							_resultado += if(axPdExc[nDet,3]<0,' color="#ff0000">','>')
							_resultado += 'R$'+  AllTrim(Transform(axPdExc[nDet,3], '@E 99,999,999.99')) +' </td>'								                    
							nxSubTot   += axPdExc[nDet,3]						
						
						Elseif axPdExc[nDet,1] == "PFE"    
						
							_resultado += '<td align="center"><font face="Calibri" size="1"'
							_resultado += if(axPdExc[nDet,3]<0,' color="#ff0000">','>')
							_resultado += 'R$'+  AllTrim(Transform(axPdExc[nDet,3], '@E 99,999,999.99')) +' </td>'								                    
							nxSubTot   += axPdExc[nDet,3]	
							
						Else
						
							If axPdExc[nDet,2] $ '2/4' .and. nValAux > 0
								nValAux := nValAux*-1
								_resultado += '<td align="center"><font face="Calibri" size="1" color="#ff0000">'+'R$'+  AllTrim(TRANSFORM(nValAux,'@E 9,999,999.99'))+' </td>'								
							Else
								_resultado += '<td align="center"><font face="Calibri" size="1">'+'R$'+  AllTrim(TRANSFORM(nValAux,'@E 9,999,999.99'))+' </td>'								
							EndIF						
							nxSubTot += nValAux						
						
							/*
								// imprimo o somatorio da coluna SUBTOTAL
								if lAchouSub
									_resultado += '<td align="center"><font face="Calibri" size="1"'
									_resultado += if(nxSubTot<0,' color="#ff0000">','>')
									_resultado += 'R$'+  AllTrim(Transform(nxSubTot, '@E 99,999,999.99')) +' </td>'								                    
				
									//abro a outra tabela de verbas para buscar a coluna correspondente. (colunas Sxx)
									TSRVS->( dbgotop() )	 
									While TSRVS->( !Eof() ) 
			//							nValAux := TSRDC->&(strtran(ALLTRIM(TSRVS->DESCR)," ",""))
										nValAux := TSRDC->&(TSRVS->CODPD)
										if TSRVS->RV_TIPOCOD $ '2/4' .and. nValAux > 0
											nValAux := nValAux*-1
											_resultado += '<td align="center"><font face="Calibri" size="1" color="#ff0000">'+'R$'+  AllTrim(TRANSFORM(nValAux,'@E 9,999,999.99'))+' </td>'								
										Else
											_resultado += '<td align="center"><font face="Calibri" size="1">'+'R$'+  AllTrim(TRANSFORM(nValAux,'@E 9,999,999.99'))+' </td>'								
										EndIF						
										// Totalizando os valores para abater do total	
										nxDifTot += nValAux
										lTemValor := if(nValAux<>0,.t.,lTemValor)
										TSRVS->( dbskip() )              
									EndDo 					
								EndIf
						*/  
						Endif
			Next								
					
			// imprimo os valores na ultima coluna TOTAL    
			nValAux := nxSubTot + nxDifTot
			_resultado += '<td align="center"><font face="Calibri" size="1"'
			_resultado += if(nValAux<0,' color="#ff0000">','>')
			_resultado += 'R$'+  AllTrim(Transform(nValAux, '@E 99,999,999.99')) +' </td>'								                    
			_resultado += '</tr>' + CRLF

			// Grava array e chama rotina para replicar dados no BackOffice
			aDados := {}
			aAdd(aDados,"")
			aAdd(aDados,"")
			aAdd(aDados,cxCNPJ)
			aAdd(aDados,"")
			aAdd(aDados,"")
			aAdd(aDados,"")
			aAdd(aDados,"")
			aAdd(aDados,cxMaoObra)
			aAdd(aDados,if(!empty(TRB->ZZF_MO),TRB->ZZF_MO,TRB->ZZC_MO))
			aAdd(aDados,"")
			aAdd(aDados,"")
			aAdd(aDados,TRB->RA_MAT)
			aAdd(aDados,TRB->RA_NOME)
			aAdd(aDados,TRB->RA_ADMISSA)
			aAdd(aDados,TRB->RA_DEMISSA)
			aAdd(aDados,TRB->RA_CC)
			aAdd(aDados,TRB->RA_SALARIO)
			aAdd(aDados,TRB->RA_HRSMES)
			aAdd(aDados,TRB->RA_SITFOLH)
			aAdd(aDados,TRB->RA_CIC)
			// clona dados do array
			aAdd(aBkpDds,aClone(aDados))
	
			If Select("TSRDC") <> 0 
				DbSelectArea("TSRDC")
				DbCloseArea()
			Endif   
				
			if empty(TRB->RA_DEMISSA) .or. lTemValor
				fWrite(nHandle, _resultado)
				nContRegs++
				nContTotal++ 
			EndIf
				       
			TRB->( dbSkip() )
			
		EndDo     
		
		_resultado := '</table>' + CRLF 
		
		fWrite(nHandle, _resultado) 
		fClose(nHandle)   
		                                  
		// fecha as tabelas
		If Select("TRB") <> 0 
			DbSelectArea("TRB")
			DbCloseArea()
		Endif  
		
		If Select("TSRV") <> 0 
			DbSelectArea("TSRV")
			DbCloseArea()
		Endif  
		
		If Select("TSRVS") <> 0 
			DbSelectArea("TSRVS")
			DbCloseArea()
		Endif  		  
		
		If Select("TZZH") <> 0 
			DbSelectArea("TZZH")
			DbCloseArea()
		Endif   		 

		If nContRegs > 0
			aadd(aLog,"   "+_cArqTmp) 
			fWrite(nHdlLog, aLog[len(aLog)] + CRLF)
		EndIf
	    
		// Verifica se existe o excel
		If !ApOleClient("MSExcel")
		   MsgAlert("Microsoft Excel não instalado. O arquivo foi gerado na pasta "+cxDiret)

		Else
		    // abro o excel baseado no arquivo html.
			oExcelApp:= MsExcel():New()
			oExcelApp:WorkBooks:Open(_cArqTmp)
			oExcelApp:SetVisible(.T.)  
			oExcelApp:Destroy()
	
		EndIf 

		// Chamar função para replicar dados no BackOffice
		FwMsgRun(, {||U_xLinkBac(aBkpDds,MV_PAR02) },"Conexão","Gerando dados no BackOffice...")

Return    

/*==================================================================================================
  Verificar os grupos a serem impressos para nao extrapolar a margem do A4.
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */
User Function fxGrupo()

//Local cQuery   := "" 
Local lAchouCln:= .f.
Local nx, nz, ny      
cAxGrp   	   := ""
aGrupos 	   := {}
lRet           := .t.

For nx:= 1 to len(aConven)
	// se o parametro agrupamento estiver preenchido deve ter um layout para todos
	If !Empty(MV_PAR03) .And. _TpArqSaida <> 2
		// retira a ultima virgula do campo devido a rotina gravar uma "," na tabela      
		cAxGrp := StrTran(Alltrim(Substr(aConven[nx,2],1,len(alltrim(aConven[nx,2]))-1)),",","")
		Exit                                                                   
	Else
		cAxGrp += StrTran(Alltrim(Substr(aConven[nx,2],1,len(alltrim(aConven[nx,2]))-1)),",","")	
	Endif	
Next 		 
For nz:=1 to len(cAxGrp) step 3
    // se no layout constar algum grupo iniciado com "S" quer dizer que terá subtotal
	If Substr(cAxGrp,nz,1) <> "S"
		aAdd(aGrupos, {Substr(cAxGrp,nz,3), Alltrim(Posicione("ZZG",1,xFilial("ZZG")+Substr(cAxGrp,nz,3),"ZZG_DESCR"))} )
		lAchouCln:= .t.
	Else 
		//aSort(aGrupos,,, {|x,y| x[1] < y[1]  })
		aAdd(aGrupos, {"SUB", "SUB TOTAL"} ) 
		For ny:= nz to len(cAxGrp) step 3     
			aAdd(aGrupos, {Substr(cAxGrp,ny,3), Alltrim(Posicione("ZZG",1,xFilial("ZZG")+Substr(cAxGrp,ny,3),"ZZG_DESCR" ))} )
		Next                        
		//aAdd(aGrupos, {"TOT" , "TOTAL"}) 		
		Exit	
	Endif	
Next

// o layout pode ter ou nao a coluna subtotal, porem a coluna total sempre terá.
If lAchouCln
	aAdd(aGrupos, {"TOT" , "TOTAL"}) 
Endif	

// verifico se extrapola a impressao na A4, no caso estou limitando a impressao de 20 colunas de verbas 
If len(aGrupos) > 22 .And. !Empty(MV_PAR03) .And. _TpArqSaida <> 2 
	//lRet:=(MsgYesNo("A quantidade de grupos para impressão extrapolou a margem. Deseja gerar planilha ?"))
    MsgAlert("A quantidade de grupos para impressão extrapolou a margem e nao sera gerado para esse convenente.")	
	/*
	If lRet
    	_ExcelLTp2:= .t.    //setar variavel para na impressao em excel e nao haver quebra de funcionarios com os grupos
    Endif
    */	
	lRet      := .f.        //seta controle de impressao no A4.   		
Else
	aConven[nx,6]:= aclone(agrupos) // adiciona o grupo ao convenente
Endif	
	                               
Return(lRet) 

/*==================================================================================================
  Verificar os grupos a serem impressos para nao extrapolar a margem do A4.
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */
User Function fxGrupo2()

//Local cQuery   := "" 
Local lAchouCln:= .f.      
Local nx, nz, ny
Local nxcntreg := len(aConven)
Local nxConta  := 0
lRet           := .t.

For nx:= 1 to len(aConven)

	cAxGrp   	   := ""
	aGrupos 	   := {}
	nxConta++
	    
	cAxGrp += StrTran(Alltrim(Substr(aConven[nx,2],1,len(alltrim(aConven[nx,2]))-1)),",","")
	
	IncProc("Criando o layout para o Convenente " + cvaltochar(nxConta) + " de " + cvaltochar(nxcntreg) )
	
	For nz:=1 to len(cAxGrp) step 3
	    // se no layout constar algum grupo iniciado com "S" quer dizer que terá subtotal
		If Substr(cAxGrp,nz,1) <> "S"
			aAdd(aGrupos, {Substr(cAxGrp,nz,3), Alltrim(Posicione("ZZG",1,xFilial("ZZG")+Substr(cAxGrp,nz,3),"ZZG_DESCR")), aConven[nx,1]} )
			lAchouCln:= .t.
		Else 
			//aSort(aGrupos,,, {|x,y| x[1] < y[1]   })
			aAdd(aGrupos, {"SUB", "SUB TOTAL", aConven[nx,1]} ) 
			For ny:= nz to len(cAxGrp) step 3     
				aAdd(aGrupos, {Substr(cAxGrp,ny,3), Alltrim(Posicione("ZZG",1,xFilial("ZZG")+Substr(cAxGrp,ny,3),"ZZG_DESCR" )), aConven[nx,1]} )
			Next                        
			//aAdd(aGrupos, {"TOT" , "TOTAL"}) 		
			Exit	
		Endif	
	Next
	
	// o layout pode ter ou nao a coluna subtotal, porem a coluna total sempre terá.
	If lAchouCln
		aAdd(aGrupos, {"TOT" , "TOTAL",aConven[nx,1]}) 
	Endif	

	// verifico se extrapola a impressao na A4, no caso estou limitando a impressao de 22 colunas de grupos 
	If len(aGrupos) > 22 
		//lRet:=(MsgYesNo("A quantidade de grupos para impressão extrapolou a margem. Deseja gerar planilha ?"))
	    MsgAlert("A quantidade de grupos para impressão extrapolou a margem e nao sera gerado para esse convenente.")
		/*
		If lRet
	    	_ExcelLTp2:= .t.    //setar variavel para na impressao em excel e nao haver quebra de funcionarios com os grupos
	    Endif                      
	    */	
		lRet      := .f.        //seta controle de impressao no A4. 
	Elseif lYes
//			aAdd(aConven[nx], agrupos ) 
			aConven[nx,6]:= aclone(agrupos) // adiciona o grupo ao convenente
	Else
		aConven[nx,6]:= aclone(agrupos) // adiciona o grupo ao convenente
	Endif	
Next 		 

Return(lRet)     


/*==================================================================================================
  Funcao para verificar verbas dentro dos grupos para impressao analitica em excel.
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */
/*
Static Function fxVerbas()

Local cQuery   := "" 
Local lAchouSub:= .f.
Local nx, nz      

// seleciona as verbas que serao impressas para cada grupo e verifico se extrapola a margem.
cQuery := " SELECT DISTINCT(RV_COD) AS CODIGO, SUBSTRING(RV_DESC,1,12) AS DESCR, RV_TIPOCOD FROM " + RetSqlName("SRV") + " SRV "
cQuery += " WHERE SRV.D_E_L_E_T_ = ' ' AND " 

For nx:= 1 to len(aConven)
	// se for agrupamento deve ter um layout para todos
	If !Empty(MV_PAR03) .And. _TpArqSaida <> 2
		// retira a ultima virgula do campo devido a rotina gravar uma "," na tabela      
		cAxGrp := StrTran(Alltrim(Substr(aConven[nx,2],1,len(alltrim(aConven[nx,2]))-1)),",","")
		Exit
	Else
		cAxGrp += StrTran(Alltrim(Substr(aConven[nx,2],1,len(alltrim(aConven[nx,2]))-1)),",","")	
	Endif	
Next 		 
For nz:=1 to len(cAxGrp) step 3
	If Substr(cAxGrp,nz,1) <> "S"
		If nz == 1
			cQuery += "  RV_XGRUPO LIKE '%"+Substr(cAxGrp,nz,3)+"%' " 	  
		Else
			cQuery += "  OR RV_XGRUPO LIKE '%"+Substr(cAxGrp,nz,3)+"%' " 
		Endif	
		//nColun+= 1
	Else 
		lAchouSub:= .t. 
		cNxtGrp += Substr(cAxGrp,nz,3)
	Endif	
Next
		
If SELECT("TSRV") > 0
	TSRV->( dbclosearea() )
Endif

TCQUERY cQuery NEW ALIAS "TSRV"  

TSRV->( dbgotop() )	 
While TSRV->( !Eof() ) 
	nColun+= 1
	TSRV->( dbSkip() )	    
Enddo 

// caso tenha verbas apos o subtotal deve-se considerar tb para contagem das colunas.
If lAchouSub     

	// seleciona as verbas que serao impressas apos subtotais.
    cQuery := " SELECT DISTINCT(RV_COD) AS CODIGO, SUBSTRING(RV_DESC,1,12) AS DESCR, RV_TIPOCOD FROM " + RetSqlName("SRV") + " SRV "
	cQuery += " WHERE SRV.D_E_L_E_T_ = ' ' AND " 
	For nz:=1 to len(cNxtGrp) step 3
		If nz == 1
			cQuery += "  RV_XGRUPO LIKE '%"+Substr(cNxtGrp,nz,3)+"%' " 	  
		Else
			cQuery += "  OR RV_XGRUPO LIKE '%"+Substr(cNxtGrp,nz,3)+"%' " 
		Endif	
		//nColun += 1
	Next           
	
	If SELECT("TSRVS") > 0
		TSRVS->( dbclosearea() )
	Endif		
	
	TCQUERY cQuery NEW ALIAS "TSRVS"  
	
Endif

TSRVS->( dbgotop() )	 
While TSRVS->( !Eof() ) 
	nColun+= 1
	TSRVS->( dbSkip() )	    
Enddo 	  

// verifico se extrapola a impressao na A4, no caso estou limitando a impressao de 20 colunas de verbas 
If nColun > 20 .And. _TpArqSaida <> 2
	lRet:=(MsgYesNo("A quantidade de grupos para impressão extrapolou a margem. Deseja que seja gerado em excel ?")) 
    If lRet
    	_TpArqSaida:= 2    //setar planilha caso ultrapasse a margem.
    	Return
	Else
		Return( Nil )
	Endif
Endif
	 
Return()
*/

/*==================================================================================================
  Busca valores do funcionario para impressao em excel.
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */
Static Function fxValores()

cxFilSrd:=TRB->RA_FILIAL
cxMatSrd:=TRB->RA_MAT
cxCCuSrd:=TRB->RA_CC
cMO     :=if(!empty(TRB->ZZF_MO),TRB->ZZF_MO,TRB->ZZC_MO)

cRetSRD := RetSqlName("SRD")
cRetSRC := RetSqlName("SRC")
cRetSRT := RetSqlName("SRT")
cRetZRD := RetSqlName("ZRD")
//cxVrbas := ""
cxQuery_:= ""    
axPdExc := {}

/*
//Despreza se nao possuir pelo menos um registro na SRD/ZRD
If !empty(TRB->RA_DEMISSA) .and. anomes(TRB->RA_DEMISSA) < MV_PAR02
	If !SRD->(dbseek(TRB->(RA_FILIAL+RA_MAT)+MV_PAR02)) 
		Return()
	EndIf
EndIf
*/            
   
// verbas que desde do inicio ate a coluna subtotal
//cQuery := " SELECT " 
TSRV->( dbgotop() )	 
While TSRV->( !Eof() )
    // seto um nome para alias da query
	cxAlias  := strtran(TSRV->DESCR," ","")
	cxPD_    := TSRV->CODIGO //Substr(TSRV->CODIGO,2,3) 
	cxNameAli:= "C"+cxPD_

	cRefFer := Posicione("SRV",1,xFilial("SRV")+cxPD_,"RV_REFFER")
	cRef13  := Posicione("SRV",1,xFilial("SRV")+cxPD_,"RV_REF13")
	cDescVb := Posicione("SRV",1,xFilial("SRV")+cxPD_,"RV_DESC")
	cPulaSRC := ""
	cPulaSRD := ""
	cPulaZRD := ""
	If cMO $ "04*05*06" .and. (cRef13=='S' .or. cRefFer=='S')
		TSRV->( dbskip() )              
		loop
	EndIf
	If cMO == '07' .and. cRef13=='S'  
		TSRV->( dbskip() )              
		loop
	EndIf
	If cMO == '07' .and. cRefFer='S' 
		If '1/3' $ cDescVb 
			TSRV->( dbskip() )              
			loop
		Else
			cPulaSRC := " and RC_TIPO2<>'F'"
			cPulaSRD := " and RD_TIPO2<>'F'"
			cPulaZRD := " and ZRD_TIPO2<>'F'"
		EndIf
	EndIf
	If !(cMO $ "04*05*06*07") .and. cRefFer='S'
		cPulaSRC := " and RC_TIPO2<>'F'"
		cPulaSRD := " and RD_TIPO2<>'F'"
		cPulaZRD := " and ZRD_TIPO2<>'F'"
	EndIf

	//Se antecipada, busca na ZRD
	If MV_PAR07 == 1
		cQuery   := " SELECT SUM("+cxNameAli+")"+cxNameAli+" FROM "	
		cQuery   += " (SELECT SUM(ZRD_VALOR) "+cxNameAli+" FROM "+ cRetZRD + " WHERE ZRD_DATARQ='"+mv_par02+"'"	
		cQuery   += " AND ZRD_MAT='"+cxMatSrd+"'"
//		cQuery   += " AND ZRD_CC='"+cxCCuSrd+"'"
		cQuery   += " AND ZRD_FILIAL='"+cxFilSrd+"'"
		cQuery   += " AND ZRD_PD='"+ cxPD_ + "'" 
		cQuery   += " AND ZRD_ROTEIR in ('FOL','131','132')" 	
		cQuery   += " AND D_E_L_E_T_=''" + cPulaZRD
	Else
	//	cQuery   += " (SELECT SUM("+cxNameAli+")"+cxNameAli+" FROM "
		cQuery   := " SELECT SUM("+cxNameAli+")"+cxNameAli+" FROM "	
		cQuery   += " (SELECT SUM(RD_VALOR) "+cxNameAli+" FROM "+ cRetSRD + " WHERE RD_DATARQ='"+mv_par02+"'"	
		cQuery   += " AND RD_MAT='"+cxMatSrd+"'"
//		cQuery   += " AND RD_CC='"+cxCCuSrd+"'"
		cQuery   += " AND RD_FILIAL='"+cxFilSrd+"'"
		cQuery   += " AND RD_PD='"+ cxPD_ + "'" 
		cQuery   += " AND RD_ROTEIR in ('FOL','131','132')" 	
		cQuery   += " AND D_E_L_E_T_=''" + cPulaSRD
		//Quando nao for folha antecipada, acrescenta union da SRC
		cQuery   += " UNION"
		cQuery   += " SELECT SUM(RC_VALOR)"+cxNameAli+" FROM" 
		cQuery   += " "+ cRetSRC + " WHERE RC_PERIODO='"+mv_par02+"'"
		cQuery   += " AND RC_MAT='"+cxMatSrd+"'"
//		cQuery   += " AND RC_CC='"+cxCCuSrd+"'"
		cQuery   += " AND RC_FILIAL='"+cxFilSrd+"'" 
		cQuery   += " AND RC_PD='"+ cxPD_ + "'" 	
		cQuery   += " AND RC_ROTEIR in ('FOL','131','132')"		      
		cQuery   += " AND D_E_L_E_T_=''" + cPulaSRC
	EndIf
//	cQuery   += ") AS C" + cxPD_ +") AS C" + cxPD_ +"," 
	cQuery   += ") AS C" + cxPD_ 
	
	If SELECT("TSRDC") > 0
		TSRDC->( dbclosearea() )
	Endif

	//conout("query",cQuery)

	TCQUERY cQuery NEW ALIAS "TSRDC"
	
	Aadd(axPdExc,{cxNameAli, Posicione("SRV",1,xFilial("SRV")+cxPD_,"RV_TIPOCOD"), TSRDC->&cxNameAli}) 
		
	TSRDC->( dbclosearea() )
	
	TSRV->( dbskip() )              
EndDo   
 
// busco os ids de provisao para pesquisa, onde conforme a mao de obra do convenente é executado uma busca para provisao. (fonte CGPE21.prw)
u_fxIdProv( if(!empty(TRB->ZZF_MO),TRB->ZZF_MO,TRB->ZZC_MO) )  
   
//dados referente a provisao, onde buscara a somatoria das verbas de 13º mes menos mes anterior
If lProvisao13  

	cxPrvMes:= cIds13oP 
	cxPrvAnt:= cIds13oP+cIds13oN 
    
	cxQuery_:= fxBusProv(cxQuery_,cxPrvMes,cxPrvAnt,"P13",cxFilSrd,cxMatSrd,cxCCuSrd)
    
    If !Empty(cxQuery_) 
    	
	    If SELECT("TSRDP") > 0
			TSRDP->( dbclosearea() )
		Endif
	
	    //cxQuery_ := fxStrtran(cxQuery_)
	    
	    TCQUERY cxQuery_ NEW ALIAS "TSRDP"
	    
	    cxNameAli:= "P13"
	    
	    Aadd(axPdExc,{cxNameAli,"1", TSRDP->&cxNameAli}) 
	    
	    //cQuery += cxQuery_
	Endif    

Endif   

//dados referente a provisao, onde buscara a somatoria das verbas de ferias mes menos mes anterior
If lProvisaoFe
    
 	cxPrvMes:= cIdsFerP + cIdsTerc 
 	cxPrvAnt:= cIdsFerP + cIdsTerc + cIdsTerB   
 	
	cxQuery_:= fxBusProv(cxQuery_,cxPrvMes,cxPrvAnt,"PFE",cxFilSrd,cxMatSrd,cxCCuSrd)
    
    If !Empty(cxQuery_)   
    
	    If SELECT("TSRDP") > 0
			TSRDP->( dbclosearea() )
		Endif
	    
		//cxQuery_ := fxStrtran(cxQuery_)
		
	    TCQUERY cxQuery_ NEW ALIAS "TSRDP"
	    
	    cxNameAli:= "PFE"
	    
	    Aadd(axPdExc,{cxNameAli,"1",TSRDP->&cxNameAli}) 
	Endif    

Endif                
/*
if lAchouSub

	// verbas que sao do grupo "S", apos a coluna SUBTOTAL ate o fim.
	TSRVS->( dbgotop() )	 
	While TSRVS->( !Eof() )
	    // seto um nome para alias da query
		cxAlias  := strtran(TSRVS->DESCR," ","")
		cxPD_    := TSRVS->CODIGO //Substr(TSRVS->CODIGO,2,3) 

		cRefFer := Posicione("SRV",1,xFilial("SRV")+cxPD_,"RV_REFFER")
		cRef13  := Posicione("SRV",1,xFilial("SRV")+cxPD_,"RV_REF13")
		cDescVb := Posicione("SRV",1,xFilial("SRV")+cxPD_,"RV_DESC")
		cPulaSRC := ""
		cPulaSRD := ""
		If cMO $ "04*05*06" .and. (cRef13=='S' .or. cRefFer=='S')
			TSRV->( dbskip() )              
			loop
		EndIf
		If cMO == '07' .and. cRef13=='S'  
			TSRV->( dbskip() )              
			loop
		EndIf
		If cMO == '07' .and. cRefFer='S' 
			If '1/3' $ cDescVb 
				TSRV->( dbskip() )              
				loop
			Else
				cPulaSRC := " and RC_TIPO2<>'F'"
				cPulaSRD := " and RD_TIPO2<>'F'"
			EndIf
		EndIf
		If !(cMO $ "04*05*06*07") .and. cRefFer='S'
			cPulaSRC := " and RC_TIPO2<>'F'"
			cPulaSRD := " and RD_TIPO2<>'F'"
		EndIf

		cQuery   += " (SELECT RD_VALOR FROM "+ cRetSRD + " WHERE RD_DATARQ='"+mv_par02+"'"
		cQuery   += " AND RD_MAT='"+cxMatSrd+"'"
		cQuery   += " AND RD_CC='"+cxCCuSrd+"'"
		cQuery   += " AND RD_FILIAL='"+cxFilSrd+"'"
		cQuery   += " AND RD_PD='"+ cxPD_ + "'" 
		cQuery   += " AND RD_ROTEIR in ('FOL','131','132')" 	
		cQuery   += " AND D_E_L_E_T_=''" + cPulaSRD	
		//Quando nao for folha antecipada, acrescenta union da SRC
		If MV_PAR07 == 2
			cQuery   += " UNION"
			cQuery   += " SELECT RC_VALOR FROM" 
			cQuery   += " "+ cRetSRC + " WHERE RC_PERIODO='"+mv_par02+"'"
			cQuery   += " AND RC_MAT='"+cxMatSrd+"'"
			cQuery   += " AND RC_CC='"+cxCCuSrd+"'"
			cQuery   += " AND RC_FILIAL='"+cxFilSrd+"'" 
			cQuery   += " AND RC_PD='"+ cxPD_ + "'" 	
			cQuery   += " AND RC_ROTEIR in ('FOL','131','132')"		      
			cQuery   += " AND D_E_L_E_T_=''" + cPulaSRC
		//Quando folha antecipada
		Else
			cQuery += " AND ZRD_TIPCAL='A'"
		EndIf
		cQuery   += ") AS C" + cxPD_ +","
		TSRVS->( dbskip() )              
	EndDo
EndIf

/*
cxVrbas:= Substr(cxVrbas,1,len(cxVrbas)-1)
cQuery := Substr(cQuery ,1,len(cQuery)-1) 

cQuery += " FROM "+ RetSqlName("SRD") + " SRD "
cQuery += " WHERE SRD.D_E_L_E_T_ <> '*' "
cQuery += " AND RD_MAT    = '"+cxMatSrd+"'  "
cQuery += " AND RD_CC     = '"+cxCCuSrd+"'  "
cQuery += " AND RD_FILIAL = '"+cxFilSrd+"'  "
cQuery += " AND RD_DATARQ = '"+MV_PAR02+"'  "	
cQuery += " AND RD_PD IN (   "+cxVrbas +" ) " //'001','149')  "
cQuery += " AND RD_ROTEIR = 'FOL' " 	  
cQuery += " GROUP BY RD_MAT " 


//Se folha antecipada, troca tabelas na query
If MV_PAR07 == 1
	cQuery := strtran(cQuery,"SRD","ZRD")  //Troca SRD por ZRD
	cQuery := strtran(cQuery,"SRT","ZRT")  //Troca SRT por ZRT
	cQuery := strtran(cQuery,"RD_","ZRD_")  //Troca campos da SRD por campos da ZRD
	cQuery := strtran(cQuery,"RT_","ZRT_")  //Troca campos da SRT por campos da ZRT
	cQuery := strtran(cQuery,"ZZRD_TIPCAL","ZRD_TIPCAL")  //Ajusta novamente o campo ZRD_TIPCAL
	cQuery := strtran(cQuery,"ZZRT_TIPCAL","ZRT_TIPCAL")  //Ajusta novamente o campo ZRT_TIPCAL
	cQuery := strtran(cQuery,"ZRT_DATACAL","ZRT_DATACA")   //Ajusta novamente o campo ZRT_DATACA
	cQuery := strtran(cQuery,"RT"+RIGHT(cRetSRT,3)+"_C","RT"+RIGHT(cRetSRT,3))   //Ajusta novamente o campo ZRT_DATACA
	cQuery := strtran(cQuery,"ZRD"+substr(cRetSRD,4,3)+"_C","ZRD"+substr(cRetSRD,4,3))
EndIf

If SELECT("TSRDC") > 0
	TSRDC->( dbclosearea() )
Endif

//conout("query",cQuery)

TCQUERY cQuery NEW ALIAS "TSRDC" 
*/

Return() 

/*==================================================================================================
  Busca convenentes que contem agrupamento.
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */
User Function fxAgrupa(cxGrupo, cTipo)

//cTipo "A"=Antecipacao, "R"=Repactuacao/Congelado, "N"=Normal

Local cDiaAntecip := if(funname()=="CGPER14",MV_PAR08,MV_PAR06)

cQuery  := ""
aArrayX := {}
cxcCCAgr:= Strtran(cxCC ,"RA_CC","'C'+ZZC_CODIGO+ZZF_CODIGO")	

cQuery := " SELECT ZZC_CODIGO AS CODIGO, ZZF_CODIGO, ZZC_MO, ZZF_MO FROM " + RetSqlName("ZZC") + " ZZC   "
cQuery += " INNER JOIN " + RetSqlName("ZZD") + " ZZD ON ZZD_CODCON = ZZC_CODIGO and ZZD_PERINI <= '"+MV_PAR02+"' and (ZZD_PERFIM >= '"+MV_PAR02+"' or ZZD_PERFIM = '')  and ZZD.D_E_L_E_T_ = '' "
cQuery += " INNER JOIN " + RetSqlName("ZZF") + " ZZF ON ZZF_CODCON = ZZD_CODCON and     ZZF_PERINI = ZZD_PERINI and ZZF.D_E_L_E_T_ = '' "
cQuery += " 									 AND ((ZZC_GRUPO = '"+cxGrupo+"' AND (ZZF_GRUPO ='' OR ZZF_GRUPO = ZZC_GRUPO)) OR       " 
cQuery += " 									      (ZZC_GRUPO = '' and ZZF_GRUPO = '"+cxGrupo+"' )) "
cQuery += " 									 AND ("+cxcCCAgr+")"
cQuery += " WHERE ZZC.D_E_L_E_T_ = '' and "        
cQuery += "       (ZZC_DTFIM = '' or left(ZZC_DTFIM,6) >= '"+MV_PAR02+"') "        
If cTipo == 'A' //Antecipados
	cQuery += " and ZZC_FOLANT = '" + cDiaAntecip + "'"
Else
	cQuery += " and ZZC_FOLANT = ''"
EndIf
If !empty(MV_PAR10)
	cQuery += " and (ZZF_MO = '" + MV_PAR10 + "' or (ZZF_MO='' and ZZC_MO = '" + MV_PAR10 + "'))"
EndIf

//cQuery += " GROUP BY ZZC_CODIGO,ZZF_CODIGO,ZZC_MO "	
cQuery += " GROUP BY ZZC_CODIGO,ZZF_CODIGO,ZZC_MO,ZZF_MO"	
cQuery += " Order by ZZC_CODIGO,ZZF_CODIGO,ZZC_MO,ZZF_MO"

If SELECT("TZZH") > 0
	TZZH->( dbclosearea() )
Endif

TCQUERY cQuery NEW ALIAS "TZZH"

TZZH->( dbgotop() )          

// crio os convenentes para geracao podendo ser um ou mais lembrando que cada um pode ter um layout e caso nao encontre o layout fixo o ZZZZ.
While TZZH->( !Eof() ) 

	cCodigo:= Posicione("ZZH",1,xFilial("ZZH")+ALLTRIM(TZZH->CODIGO),"ZZH_CODIGO")
	cCodigo:= Iif(Empty(cCodigo),'ZZZZ',cCodigo)
	cDescri:= Iif(cCodigo == 'ZZZZ',"PADRAO",ALLTRIM(Posicione("ZZC",1,xFilial("ZZC")+ALLTRIM(cCodigo),"ZZC_DESCR")))   
	cConvnt:= TZZH->CODIGO + TZZH->ZZF_CODIGO
//	cMaoObr:= Iif(cCodigo == 'ZZZZ',"04"    ,TZZH->ZZC_MO )   // codigo "04" quer dizer com provisao "fxIdProv"
	cMaoObr:= if(!empty(TZZH->ZZF_MO),TZZH->ZZF_MO,TZZH->ZZC_MO)

    // caso ja encontre o convenente nao adicionar novamente.
	//If !(nPos := Ascan(aArrayX,{|x| x[1] == cCodigo })) > 0			
		aAdd( aArrayX, { cCodigo, ALLTRIM(Posicione("ZZH",1,xFilial("ZZH")+ALLTRIM(cCodigo),"ZZH_GRUPO")), cDescri, cConvnt, cMaoObr,"" } )					
	//Endif	

	TZZH->( dbskip() )
	
Enddo

// verifico se dentro dos convenentes selecionados possui o layout padrao ZZZZ e se existe cadastrado.
If (nPos := Ascan(aArrayX,{|x| x[1] == 'ZZZZ' })) > 0
   	dBSelectArea("ZZH")
	dBGoTop()
	If !(ZZH->(dbSeek(xFilial("ZZH")+'ZZZZ')))
			Help( ,, 'HELP',, "Não foi encontrado o layout padrao 'ZZZZ' cadastrado, portanto será abortado a impressão. Cadastre-o !! ", 1, 0 ) 
			Return( Nil )
	Endif		
EndIf	     

Return(aArrayX)

/*==================================================================================================
  Busca convenentes que "contem" ou "nao" agrupamento dentro dos parametros De-Ate
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */    
User Function fConvAgrp(aArrayX,cTemGrp,cTipo)

//cTipo "A"=Antecipacao, "R"=Repactuacao/Congelado, "N"=Normal

Local cDiaAntecip := if(funname()=="CGPER14",MV_PAR08,MV_PAR06)
Local nxxTotReg   := nxConta:= 0
Local cMxgProc    := Iif(cTemGrp == "S", "Filtrando Convenentes Com Agrupamento..","Filtrando Convenentes..")  

cQuery  := 	cCodigo:= 	cDescri:= ""
aArrayX := {}
cxcCCAgr:= Strtran(cxCC ,"RA_CC","'C'+ZZC_CODIGO+ZZF_CODIGO")	

If cTemGrp == "S"
	cQuery := " SELECT DISTINCT 'C'+ZZC_CODIGO+ZZF_CODIGO AS CODIGO, ZZC_MO, ZZF_MO, ZZF_GRUPO, ZZC_GRUPO FROM " + RetSqlName("ZZC") + " ZZC "
	cQuery += " INNER JOIN " + RetSqlName("ZZD") + " ZZD ON ZZD_CODCON = ZZC_CODIGO AND ZZD_PERINI <= '"+MV_PAR02+"' and (ZZD_PERFIM >= '"+MV_PAR02+"' OR ZZD_PERFIM = '')  and ZZD.D_E_L_E_T_ = ''  "
	cQuery += " INNER JOIN " + RetSqlName("ZZF") + " ZZF ON ZZF_CODCON = ZZD_CODCON AND ZZF_PERINI = ZZD_PERINI AND ZZF.D_E_L_E_T_ = '' AND "                                                         
	cQuery += "                                      ( ZZF_GRUPO <> '' OR ZZC_GRUPO  <> '' ) AND  "
	cQuery += " 									 ("+cxcCCAgr+")"
	cQuery += " WHERE ZZC.D_E_L_E_T_ = '' AND (ZZC_DTFIM = '' OR left(ZZC_DTFIM,6) >= '"+MV_PAR02+"') "                      
	If cTipo == 'A' //Antecipados
		cQuery += " and ZZC_FOLANT = '" + cDiaAntecip + "'"
	Else
		cQuery += " and ZZC_FOLANT = ''"
	EndIf
	If !empty(MV_PAR10)
		cQuery += " and (ZZF_MO = '" + MV_PAR10 + "' or (ZZF_MO='' and ZZC_MO = '" + MV_PAR10 + "'))"		
	EndIf
	cQuery += " Order by 1"
Else   

	cQuery := " SELECT DISTINCT 'C'+ZZC_CODIGO+ZZF_CODIGO AS CODIGO, ZZC_MO, ZZF_MO, ZZC_DESCR FROM " + RetSqlName("ZZC") + " ZZC "
	cQuery += " INNER JOIN " + RetSqlName("ZZD") + " ZZD ON ZZD_CODCON = ZZC_CODIGO and ZZD_PERINI <= '"+MV_PAR02+"' and (ZZD_PERFIM >= '"+MV_PAR02+"' or ZZD_PERFIM = '')  and ZZD.D_E_L_E_T_ = '' " 
	cQuery += " INNER JOIN " + RetSqlName("ZZF") + " ZZF ON ZZF_CODCON = ZZD_CODCON and ZZF_PERINI = ZZD_PERINI and ZZF.D_E_L_E_T_ = '' and "
	cQuery += "                                      ("+cxcCCAgr+")"
	cQuery += " WHERE ZZC.D_E_L_E_T_ = '' AND (ZZC_DTFIM = '' OR left(ZZC_DTFIM,6) >= '"+MV_PAR02+"') "                      
	If cTipo == 'A' //Antecipados
		cQuery += " and ZZC_FOLANT = '" + cDiaAntecip + "'"
	Else
		cQuery += " and ZZC_FOLANT = ''"
	EndIf
	If !empty(MV_PAR10)
		cQuery += " and (ZZF_MO = '" + MV_PAR10 + "' or (ZZF_MO='' and ZZC_MO = '" + MV_PAR10 + "'))"
	EndIf
	cQuery += " and 'C'+ZZC_CODIGO+ZZF_CODIGO not in (  "
	cQuery += "                                       SELECT DISTINCT 'C'+ZZC_CODIGO+ZZF_CODIGO AS CODIGO  FROM " + RetSqlName("ZZC") + " ZZC "
	cQuery += "                                       INNER JOIN " + RetSqlName("ZZD") + " ZZD ON ZZD_CODCON = ZZC_CODIGO and ZZD_PERINI <= '"+MV_PAR02+"' "
	cQuery += "                                       AND (ZZD_PERFIM >= '"+MV_PAR02+"' or ZZD_PERFIM = '')  and ZZD.D_E_L_E_T_ = '' " 
	cQuery += "                                       INNER JOIN " + RetSqlName("ZZF") + " ZZF ON ZZF_CODCON = ZZD_CODCON and ZZF_PERINI = ZZD_PERINI and ZZF.D_E_L_E_T_ = '' and  "
	cQuery += "                                       ( ZZF_GRUPO <> '' or ZZC_GRUPO  <> '' ) and  "
	cQuery += "                                       ("+cxcCCAgr+")"   
	cQuery += " WHERE ZZC.D_E_L_E_T_ = '' and (ZZC_DTFIM = '' or left(ZZC_DTFIM,6) >= '"+MV_PAR02+"')"
	If cTipo == 'A' //Antecipados
		cQuery += " and ZZC_FOLANT = '" + cDiaAntecip + "'"
	Else
		cQuery += " and ZZC_FOLANT = ''"
	EndIf
	If !empty(MV_PAR10)
		cQuery += " and (ZZF_MO = '" + MV_PAR10 + "' or (ZZF_MO='' and ZZC_MO = '" + MV_PAR10 + "'))"
	EndIf
	cQuery += " )"
	cQuery += " Order by 1"

Endif

If SELECT("TCTT") > 0
	TCTT->( dbclosearea() )
Endif 

TCQUERY cQuery NEW ALIAS "TCTT"
Count To nxxTotReg
ProcRegua(nxxTotReg)

TCTT->( dbgotop() ) 

While TCTT->( !Eof() ) 
    
    nxConta++
    // possui agrupamento
	If cTemGrp == "S"
		If !(nPos := Ascan(aArrayX,{|x| x[1] == If(Empty(TCTT->ZZF_GRUPO),TCTT->ZZC_GRUPO,TCTT->ZZF_GRUPO) })) > 0			
			aAdd( aArrayX, { If(Empty(TCTT->ZZF_GRUPO),TCTT->ZZC_GRUPO,TCTT->ZZF_GRUPO) } )					
		Endif
		cCodigo:= TCTT->ZZC_GRUPO
		cDescri:= "" 	         
	// nao possui agrupamento e prepara o aconven para impressao de-ate com as posicoes corretas.	
	Else                                                             
// caso ja encontre o convenente nao adicionar novamente.		
		If !(nPos := Ascan(aArrayX,{|x| x[1] == TCTT->CODIGO })) > 0			

			cCodigo:= Posicione("ZZH",1,xFilial("ZZH")+ Substr(TCTT->CODIGO,2,4),"ZZH_CODIGO")
			cCodigo:= Iif(Empty(cCodigo),'ZZZZ',cCodigo)
			cDescri:= TCTT->ZZC_DESCR //Iif(cCodigo == 'ZZZZ',"PADRAO",TCTT->ZZC_DESCR)   
			cConvnt:= TCTT->CODIGO
			cMaoObr:= if(!empty(TCTT->ZZF_MO),TCTT->ZZF_MO,TCTT->ZZC_MO) 

			aAdd( aArrayX, { cCodigo, ALLTRIM(Posicione("ZZH",1,xFilial("ZZH")+cCodigo,"ZZH_GRUPO")), cDescri, cConvnt, cMaoObr } )					
		Endif	
	Endif
	
	IncProc(cMxgProc + " " + cvaltochar(nxConta) + " de " + cvaltochar(nxxTotReg) + " - " + cCodigo + " / " + cDescri)
	
	TCTT->( dbskip() )
	
Enddo

aSort(aArrayX,,,{|x,y| x[1] < y[1]})

IncProc( "Aguarde.... Em processamento..")

Return(aArrayX)

/*==================================================================================================
  Busca convenentes para impressao em excel.
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */ 
Static Function fExcConv(aArrayX)

cQuery  := cxAnt:= ""
aArrayX := {}

cQuery := " SELECT DISTINCT(SUBSTRING(CTT_CUSTO,2,4)) AS CODIGO FROM " + RetSqlName("CTT") + " CTT "
cQuery += " INNER JOIN " + RetSqlName("ZZC") + " ZZC ON ZZC_CODIGO = SUBSTRING(CTT_CUSTO,2,4) and ZZC.D_E_L_E_T_ = '' and (ZZC_DTFIM = '' or left(ZZC_DTFIM,6) >= '"+MV_PAR02+"') "		
If MV_PAR07 == 1 //Antecipados
	cQuery += " and ZZC_FOLANT = '" + MV_PAR08 + "'"
Else
	cQuery += " and ZZC_FOLANT = ''"
EndIf
cQuery += " INNER JOIN " + RetSqlName("ZZD") + " ZZD ON ZZD_CODCON = ZZC_CODIGO and ZZD_PERINI <= '"+MV_PAR02+"' and (ZZD_PERFIM >= '"+MV_PAR02+"' or ZZD_PERFIM = '')  and ZZD.D_E_L_E_T_ = '' "
cQuery += " INNER JOIN " + RetSqlName("ZZF") + " ZZF ON ZZF_CODCON = ZZD_CODCON and ZZF_PERINI = ZZD_PERINI and ZZF.D_E_L_E_T_ = '' " 
cQuery += " WHERE CTT.D_E_L_E_T_ = '' AND " + STRTRAN(cxCC,"RA_CC","CTT_CUSTO") + " "
If !empty(MV_PAR10)
	cQuery += " and (ZZF_MO = '" + MV_PAR10 + "' or (ZZF_MO='' and ZZC_MO = '" + MV_PAR10 + "'))"
EndIf
cQuery += " Order by 1"

If SELECT("TEXCL") > 0
	TEXCL->( dbclosearea() )
Endif

TCQUERY cQuery NEW ALIAS "TEXCL"

TEXCL->( dbgotop() )
    
// crio os convenentes para geracao podendo ser um ou mais lembrando que cada um pode ter um layout.
While TEXCL->( !Eof() ) 

	cCodigo:= Posicione("ZZH",1,xFilial("ZZH")+ALLTRIM(TEXCL->CODIGO),"ZZH_CODIGO")
	cCodigo:= Iif(Empty(cCodigo),'ZZZZ',cCodigo)
	cDescri:= Iif(cCodigo == 'ZZZZ',"PADRAO",ALLTRIM(Posicione("ZZC",1,xFilial("ZZC")+ALLTRIM(cCodigo),"ZZC_DESCR")))   
//	cMaoObr:= Iif(cCodigo == 'ZZZZ',"04"    ,ALLTRIM(Posicione("ZZC",1,xFilial("ZZC")+ALLTRIM(cCodigo),"ZZC_MO")))   // codigo "04" quer dizer com provisao "fxIdProv"
    cMaoObr:= '' //Nao envia mao de obra no aConve pois utilizara a Mao de Obra da query quando busca pelo SRA indo novamente para ZZC e ZZF

	aAdd( aArrayX , { cCodigo, ALLTRIM(Posicione("ZZH",1,xFilial("ZZH")+ALLTRIM(cCodigo),"ZZH_GRUPO")), cDescri, ALLTRIM(TEXCL->CODIGO), cMaoObr } )		
    
    cxGrupo:= StrTran(ALLTRIM(Posicione("ZZH",1,xFilial("ZZH")+ALLTRIM(cCodigo),"ZZH_GRUPO")),",","")
    //verifico duplicidade de grupo	
	For nxg:= 1 to len(cxGrupo) step 3
		cxAnt:= Substr(cxGrupo,nxg,3)
		nPos := 0
		If !(nPos := Ascan(aaAGrp,{|x| x[1] == cxAnt })) > 0
			aAdd( aaAGrp , { cxAnt } )				
		Endif
	Next	
	TEXCL->( dbskip() )
	

Enddo

// verifico se dentro dos convenentes selecionados possui o layout padrao ZZZZ e se existe cadastrado.
If (nPos := Ascan(aArrayX,{|x| x[1] == 'ZZZZ' })) > 0
    	dBSelectArea("ZZH")
	dBGoTop()
	If !(ZZH->(dbSeek(xFilial("ZZH")+'ZZZZ')))
			Help( ,, 'HELP',, "Não foi encontrado o layout padrao 'ZZZZ' cadastrado, portanto será abortado a impressão. Cadastre-o !! ", 1, 0 ) 
			Return( Nil )
	Endif		
EndIf    

aSort(aArrayX,,,{|x,y| x[1] < y[1]})

Return(aArrayX)

/*==================================================================================================
  Funcao para montar a query da provisao p/13º ou ferias buscando o movimento atual menos o movimento
  anterior
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */
Static Function fxBusProv(cxQuery_,cxPrvMes,cxPrvAnt,cProv,cxFilSrd,cxMatSrd,cxCCuSrd)

cxQuery_:= ""  

If !Empty(cxPrvMes) .or. !Empty(cxPrvAnt)
	cRetSRV := RetSqlName("SRV")
	cRetSRT := RetSqlName("SRT")

	If !Empty(cxPrvMes)  
		 If	_TpArqSaida <>  2		 
			 cxQuery_   := " ("
		 	 cxQuery_   += " SELECT(SELECT SUM ("+cProv+") "+cProv+" FROM ("
		 Else
		 	 cxQuery_   += " SELECT SUM ("+cProv+") "+cProv+" FROM ("		 
		 Endif	 
		 cxQuery_   += " SELECT SUM(RT_VALOR) "+cProv+" "
		 cxQuery_   += " FROM "+ cRetSRT + " SRT"
		 cxQuery_   += " INNER JOIN "+ cRetSRV + " SRV ON RV_COD=RT_VERBA and SRV.D_E_L_E_T_=''" 
		 cxQuery_   += " WHERE SRT.D_E_L_E_T_=''"
		 cxQuery_   += " AND RT_VERBA IN (SELECT RV_COD FROM "+cRetSRV+" WHERE D_E_L_E_T_='' AND RV_CODFOL IN ("+cxPrvMes+"))"  
		 cxQuery_   += " AND SUBSTRING(RT_DATACAL,1,6)='"+mv_par02+"'"
		 cxQuery_   += " AND RT_MAT='"+cxMatSrd+"'"
		 cxQuery_   += " AND RT_CC='"+cxCCuSrd+"'"
		 cxQuery_   += " AND RT_FILIAL='"+cxFilSrd+"'"                          
		//Se folha antecipada
		If MV_PAR07 == 1
			cxQuery_ := strtran(cxQuery_,"SRT","ZRT")  				//Troca SRT por ZRT
			cxQuery_ := strtran(cxQuery_,"RT_","ZRT_")  				//Troca campos da SRT por campos da ZRT
			cxQuery_ := strtran(cxQuery_,"ZRT_DATACAL","ZRT_DATACA")  //Ajusta novamente o campo ZRT_DATACA
			cxQuery_ := strtran(cxQuery_,"WHERE ","WHERE ZRT_TIPCAL='A' AND ")  //Acrescenta condicao no where
		EndIf
	Endif     
	
	If !Empty(cxPrvAnt)
		 //Mes anterior deve buscar sempre da SRT, mesmo quando folha antecipada
		 cxPerAnt := cValtoChar(AnoMes(monthSub(stod(mv_par02+"01"),1))) 
		 cxQuery_   += " UNION"
		 cxQuery_   += " SELECT SUM(RT_VALOR*-1) "+cProv+" "
		 cxQuery_   += " FROM "+ cRetSRT + " SRT"
		 cxQuery_   += " INNER JOIN "+ cRetSRV + " SRV ON RV_COD=RT_VERBA and SRV.D_E_L_E_T_=''" 
		 cxQuery_   += " WHERE SRT.D_E_L_E_T_=''"
		 cxQuery_   += " AND RT_VERBA IN (SELECT RV_COD FROM "+cRetSRV+" WHERE D_E_L_E_T_='' AND RV_CODFOL IN ("+cxPrvAnt+"))"  
		 cxQuery_   += " AND SUBSTRING(RT_DATACAL,1,6)='"+cxPerAnt+"'"
		 cxQuery_   += " AND RT_MAT='"+cxMatSrd+"'"
		 cxQuery_   += " AND RT_CC='"+cxCCuSrd+"'"
		 cxQuery_   += " AND RT_FILIAL='"+cxFilSrd+"'"  
		 cxQuery_   += " ) AS "+cProv 
	Endif 
	If	_TpArqSaida <>  2         
		cxQuery_   += ") " +cProv + ") "+cProv+"," 
	Endif	
	
EndIf

Return(cxQuery_)


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³ cgpr14Ok      ³ Autor ³ Equipe RH 		     ³ Data ³18/06/13  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Confirma configuracao de parametros. 						   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ CGPER14						                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function cgpr14Ok()

Local lRet := .t.

//Se Html/Excel detalhado
If MV_PAR04 == 2
	//nao pode permitir agrupamento
 	If !empty(MV_PAR03)
		MsgStop("Não pode informar agrupamento quando selecionado formato em Html/Excel Detalhado.")
		lRet := .f.
 	ElseIf empty(MV_PAR01)
		MsgStop("O preenchimento de intervalo de Centro de Custo é obrigatório quando selecionado formato em Html/Excel Detalhado.")
		lRet := .f.
	EndIf
EndIf

Return (lRet)
/*==================================================================================================
  Carrega arrays utilizados no relatorio 
  MIT044 - Especificacao_de_Personalizacao - Ressarcimento_APD_vs2
@author     A.Shibao
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */
Static Function fxCArrays(aMO,aSit,aMuni)	

//Busca descricoes dos tipos de mao de obra
aMO := {}
If SX5->(dbseek(xFilial("SX5")+"_0"))
	While SX5->(!eof()) .and. SX5->X5_TABELA=='_0'
		aadd(aMO,{alltrim(SX5->X5_CHAVE),alltrim(SX5->X5_DESCRI)})
		SX5->(dbskip())
	EndDo
EndIf  

//Busca descricoes de situacoes
aSit := {}
If SX5->(dbseek(xFilial("SX5")+"31"))
	While SX5->(!eof()) .and. SX5->X5_TABELA=='31'
		aadd(aSit,{alltrim(SX5->X5_CHAVE),alltrim(SX5->X5_DESCRI)})
		SX5->(dbskip())
	EndDo
EndIf	

//Busca descricoes de municipios dos convenentes.  
aMuni := {}
DbSelectArea("CC2")
DbSetOrder(1)
DbGotop()
While CC2->(!eof()) 
		aadd(aMuni,{alltrim(CC2->CC2_EST),alltrim(CC2->CC2_CODMUN),alltrim(CC2->CC2_MUN)})
		CC2->(dbskip())
EndDo    

Return


/*==================================================================================================
  Funcao para insert de texto 
@author     
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */
User Function fGetAux(cTitulo,nTam,cPicture,nAlt,nCompr)
Local oDlg
Local cGetVar := space(nTam)
Local oGet
Local oBtn1,oBtn2
Local lOk := .F. 

Default nAlt   := 100
Default nCompr := 500

DEFINE DIALOG oDlg TITLE (cTitulo) ;
    FROM 0,0 TO nAlt,nCompr ;      
    COLOR CLR_BLACK, CLR_HBLUE PIXEL

@ 05,05 GET oGet VAR cGetVar  PICTURE (cPicture) ;
        SIZE (nTam*4),12 OF oDlg PIXEL 

@ 25,05  BUTTON oBtn1 PROMPT "Confirmar" SIZE 40,15 ; 
         ACTION (lOk := .T. , oDlg:End()) OF oDlg PIXEL 

@ 25,50  BUTTON oBtn2 PROMPT "Voltar" SIZE 40,15 ; 
         ACTION (oDlg:End()) OF oDlg PIXEL 

ACTIVATE DIALOG oDlg CENTER

If !lOk
   cGetVar := "@"
Endif

Return cGetVar



/*==================================================================================================
  Funcao para troca de caracteres nas querys
@author     
@since      
@param
@version    P12
@return
@project
@client    Ciee 
//================================================================================================== */
/*Static Function fxStrtran(cQuery)

//Se folha antecipada, troca tabelas na query
If MV_PAR07 == 1
	cQuery := strtran(cQuery,"SRD","ZRD")  //Troca SRD por ZRD
	cQuery := strtran(cQuery,"SRT","ZRT")  //Troca SRT por ZRT
	cQuery := strtran(cQuery,"RD_","ZRD_")  //Troca campos da SRD por campos da ZRD
	cQuery := strtran(cQuery,"RT_","ZRT_")  //Troca campos da SRT por campos da ZRT
	cQuery := strtran(cQuery,"ZZRD_TIPCAL","ZRD_TIPCAL")  //Ajusta novamente o campo ZRD_TIPCAL
	cQuery := strtran(cQuery,"ZZRT_TIPCAL","ZRT_TIPCAL")  //Ajusta novamente o campo ZRT_TIPCAL
	cQuery := strtran(cQuery,"ZRT_DATACAL","ZRT_DATACA")   //Ajusta novamente o campo ZRT_DATACA
	cQuery := strtran(cQuery,"RT"+RIGHT(cRetSRT,3)+"_C","RT"+RIGHT(cRetSRT,3))   //Ajusta novamente o campo ZRT_DATACA
	cQuery := strtran(cQuery,"ZRD"+substr(cRetSRD,4,3)+"_C","ZRD"+substr(cRetSRD,4,3))
EndIf

Return(cQuery)*/