#include 'protheus.ch'

/* ========================================================================== 
Código-fonte de teste do Grid Client - Utilização com Prepare() e Execute()
=========================================================================== */
User Function GridBeta()
Local aStart := {1,2}
Local oGrid
Local nTimer := seconds()
Local lGridOk := .f. , nI

// Cria o objeto Client de interface com o Grid
oGrid := GridClient():New()

// Define o nome das funções de preparação de ambiente e execução
cFnStart := 'U_TGRIDS'
cFnExec  := 'U_TGRIDA'

lGridOk := oGrid:Prepare(cFnStart,aStart,cfnExec)

If !lGridOk   
    // Caso o Grid não tenha sido preparado com sucesso, recupere   
    // os detalhes e mensagem de erro através do método GetError()   
    MsgStop(oGrid:GetError(),"Falha de Preparação do Grid")   
    // Finaliza o processo   
    oGrid:Terminate()   
    // Este objeto não pode ser mais usado . Limpa   
    oGrid := NIL   
    Return
Endif

    // Parte pra execução – Envio de 200 requisições
    For nI := 1 to 200   
        // Looping de envio de dados   
        // O parâmetro de execução enviado é un número   
        lGridOk := oGrid:Execute(nI)   
        If !lGridOk           
            EXIT   
        Endif
    Next

    If lGridOk   
        // Até aqui, sem erros? Ok, finaliza o Grid.   
        lGridOk := oGrid:Terminate()   
    Endif

    IF !lGridOk   
        
        // Houve algum erro, ou no processamento, ou na   
        // finalização do Grid. Verifica os arrays de propriedades   
        If !empty(oGrid:aErrorProc)          
            // Houve um ou mais erros fatais que abortaram o processo          
            // [1] : Número sequencial da instrução enviada que não foi processada          
            // [2] : Parâmetro enviado para processamento          
            // [3] : Identificação do Agente onde ocorreu o erro          
            // [4] : Detalhes da ocorrência de erro          
            varinfo('ERR',oGrid:aErrorProc)   
        Endif   

        If !empty(oGrid:aSendProc)          
            // retorna lista de chamadas que foram enviadas e não foram executadas          
            // [1] Número sequencial da instrução          
            // [2] Parâmetro de envio          
            // [3] Identificação do Agente que recebeu a requisição          
            varinfo('PND',oGrid:aSendProc)   
        Endif   
            
        MsgStop(oGrid:GetError(),"Falha de Processamento em Grid")
    Else   
        // Tudo certo   
        MsgInfo("Processamento completo com sucesso em "+str(seconds()-nTimer,12,3))
    Endif

Return

STATIC _ReqNum := 0
// =====================================================================
// Preparação de ambiente
// Executada por cada agente, para preparar o ambiente para rodar
// a função de processamento do Grid
// Num Grid para executar funções que dependem de infraestrutura do ERP,
// neste ponto deve ser colocado um PREPARE ENVIRONMENT
// =====================================================================

USER Function TGRIDS()
    Conout("[DEMO] Preparando Ambiente")
    // Espera randômica, para consumir algum tempo  (de 1 a 10 segundos )
    sleep( Randomize(1000,10000) )
    Conout("[DEMO] Ambiente Preparado")
Return .T.
// =====================================================================
// Execução de Requisições de Processamento
// Recebe como parâmetro o conteúdo informado ao método Execute()
// Caso não haja nenhuma necessidade de conteúdo retornado
// diretamente pela chamada, a função deve retornar NIL.
// Caso seja retornado qualquer outro valor, ele será
// armazenado pelo GridClient e poderá ser recuperado posteriormente
// =====================================================================

USER Function TGRIDA(xParam)
    Conout("[DEMO] REQUISICAO ["+str(++_ReqNum,4)+"] Processando Parametro ["+str(xParam,4)+"]")
    // Espera randômica, para consumir algum tempo ( entre 0,5 e 5 segundos )
    sleep( Randomize(500,5000) )
    Conout("[DEMO] REQUISICAO ["+str(++_ReqNum,4)+"] OK")
Return 
