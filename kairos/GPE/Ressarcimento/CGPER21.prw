#include 'protheus.ch'
#include 'tdsBirt.ch'
#include 'birtdataset.ch'
/*==================================================================================================
	Relatório BIRT - CGPER21 - chamado na funcao CGPER14.PRW
    Conversão relatório de ressarcimento
@author     D.Hirabara
@since      
@param
@version    P12
@return
@project
@client    Ciee 
/================================================================================================== */
User function CGPER21(cTpDesign,cAgrupador,nX2)
	
	Local oReport, cArquivo, nPos
	
	Private nxConv:= 0 //Variavel usada dentro do CGPE21.prw apos chamar o BIRT
                                                                 
	Default cAgrupador := ''

   	//Executa para cada convenente existente no aConven, que é alimentado pela fxAgrupa e fConvAgrp, ambas
   	//funcoes existente no CGPER14.prw, gerando um PDF para cada aConven
   	//For nX := 1 to len(aConven)

		nxConv := nX2
		nContRegs := 0

   	    // seto o grupo/layout correto para impressao quando nao utiliza um agrupamento especifico
		If empty(MV_PAR03)
	   		aGrupos:= aclone(aConven[nxConv,6])          
   		EndIf
   		
		nDescon	:= MV_PAR05
		nAcresc	:= MV_PAR06	
		cMV_PAR02:= MV_PAR02
		
   		//A partir deste momento, executa o BIRT chamando o dataset configurado no CGPE21.prw                                                         
   		cWTabAlias  := "XRESS_"+dtos(date())+StrTran(TIME(),":","")
		oReport:= CIEEBIRTReport():CIEEBIRTReport(cTpDesign)
		oReport:setTitle("Ressarcimento")
		oReport:lPergunte := .F.
		oReport:layout(cTpDesign)                     
		If _TpArqSaida == 3
			oReport:format("XLS")
		Else
			oReport:format("PDF")
		EndIf
		oReport:nOrient:= 2                  
		oReport:prepare()                  

		If lAgrupa
			cArquivo := cxDiret+"AGRUPAMENTO_"+Alltrim(cAgrupador)+"_"+mv_par02
			cArquivo += "_"+dtos(date())+StrTran(TIME(),":","")+ if(_TpArqSaida==3,".xls",".pdf")				
		Else
			cArquivo := cxDiret+Alltrim(Substr(aConven[nxConv,4],2,4))+"_"+strtran(Strtran(Alltrim(aConven[nxConv,3]),"/",""),"\","")+"_"+mv_par02					
			cArquivo += "_"+dtos(date())+StrTran(TIME(),":","")+ if(_TpArqSaida==3,".xls",".pdf")				
		EndIf

		//Se ja existe PDF com o mesmo nome 
		If File(cArquivo)

			//Deleta o PDF anterior
			If !(fErase(cArquivo) == 0)
				cMsg := '   Ocorreram problemas na tentativa de deleção do arquivo '+AllTrim(cArquivo)+'.'+CRLF+'Esse arquivo continuará com o conteúdo anterior.'
				MsgStop(cMsg)
				aadd(aLog,cMsg)
				fWrite(nHdlLog, aLog[len(aLog)] + CRLF)
				freeObj(oReport)
				Return //Exit
			EndIf

		EndIf

		If nContRegs > 0
			nPos := len(aTotais)
//			aadd(aLog,"   "+padr(cArquivo,60)+padr(aTotais[nPos,1],12)+If('Indiv'$aTotais[nPos,1],space(15),aTotais[nPos,2])+"  Func:  "+strzero(aTotais[nPos,3],4)+"   Valor: "+Transform( aTotais[nPos,4]+nAcresc-nDescon, '@E 99,999,999.99')) 
			aadd(aLog,"   "+padr(cArquivo,90)+padr(aTotais[nPos,1],12)+If('Indiv'$aTotais[nPos,1],space(15),aTotais[nPos,2])+"  Func:  "+strzero(aTotais[nPos,3],4)+"   Valor: "+Transform( aTotais[nPos,4]+aTotais[nPos,5]-aTotais[nPos,6], '@E 99,999,999.99')) 
			fWrite(nHdlLog, aLog[len(aLog)] + CRLF)
			oReport:saveReport(cArquivo)
			If !file(cArquivo)
				aadd(aLog,"***"+padr(cArquivo,90)+" *** NAO GERADO POR TIMEOUT DE REDE ***") 
				fWrite(nHdlLog, aLog[len(aLog)] + CRLF)
			EndIf
		Endif
		
		freeObj(oReport)

		//significa que é agrupamento entao nao continuo no for, pois sera impresso apenas 1 relatorio.   
		If lAgrupa .or. lDeAte
		     Return //Exit
		Endif

		//Caso a fResImpr existente no CGPE21.prw alterar o nxConv por conta de gerar todos os
		//aConven pertecentes ao mesmo Convenente sem agrupador, avanca o nX para o proximo convenente
		/*If nxConv > nx
			nx := nxConv
		EndIf
        */
	//Next nX	
    
return oReport

