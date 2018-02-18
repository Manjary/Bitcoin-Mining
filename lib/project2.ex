defmodule Project2 do

    def main(args \\ []) do
        {check,_}=:inet_parse.strict_address('#{args}')
        {n, _} =  :string.to_integer(to_charlist(args))
        IO.puts check
        case check do
          :error->startServerNode(n)
          :ok->startClientNode(to_string(args))
        end
    end

    def startConnection(serverNodeName) do
        IO.puts "Inside Server"
        Node.connect(String.to_atom(serverNodeName))
        #IO.puts Node.list 
        :timer.sleep(100000)
        IO.puts  "Connection done"
        #:global.sync() 
        #temp = :global.whereis_name(:server)
        #send(temp,{:id,workerNodeName})
    end

    def startServerNode(n) do
        #startNode(n)
        spawn(fn-> Project2.startNode(n) end)  
        #Enum.map(1..4,fn(_) -> spawn_link(serverMining(n))end)
        Enum.each(1..7, fn(i)-> spawn(fn-> serverMining(n) end) end)
        spawn(serverMining(n))

    end

    def startNode(n) do
        IO.puts "Inside startNode"
        {:ok,[{ip1,_,_}|tail]}=:inet.getif()
        localIp = List.to_string(:inet_parse.ntoa(ip1))
        IO.puts localIp
        unless Node.alive?() do
        {:ok, _} = Node.start(String.to_atom("server@"<>localIp))
        end
        cookie = Application.get_env(String.to_atom("server@"<>localIp) , :cookie)
        Node.set_cookie(cookie)
        #:global.register_name(:server, self())
        IO.puts "Node started"
        :ets.new(:count_registry, [:named_table])
        :ets.insert(:count_registry, {"List", length(Node.list)})
        waitForConnection(n)
    end

    def waitForConnection(n) do
        if (length(Node.list) != 0) do
          [{_,test}]=:ets.lookup(:count_registry, "List")
          IO.puts test
          if(test != length(Node.list)) do
             workerIp = List.last(Node.list)
          end
          #:timer.sleep(1000)
          #workerIp = List.first(Node.list)
          #IO.puts workerIp
          distributeWork(workerIp,n)
          :ets.insert(:count_registry, {"List", length(Node.list)})
 
          waitForConnection(n)
        else
          #IO.puts "Inside else"
          waitForConnection(n)
        end 
        
        #receive do
        #{:id,msg} -> {inspect msg}
        #end
        #waitForConnection()

    end

    def startClientNode(serverIp) do
        {:ok,[{ip,_,_}|tail]}=:inet.getif()
        workerIp = List.to_string(:inet_parse.ntoa(ip))
        {:ok,hostName} = :inet.gethostname()
        hostName = to_string(hostName)
        unless Node.alive?() do
        {:ok, _} = Node.start(String.to_atom(hostName<>"@"<>workerIp))
        end
        cookie = Application.get_env(String.to_atom(hostName<>"@"<>workerIp) , :cookie)
        Node.set_cookie(cookie)
        IO.puts "Inside CLient"
        #IO.puts Node.self
        #IO.puts [node|Node.list]
        startConnection("server@"<>serverIp)
    end

    def serverMining(n) do
        #i = Enum.random(8..16)
        input = :crypto.strong_rand_bytes(8) |> Base.url_encode64 |> binary_part(0,8)
        finalstring = "rameshwari.oblar;"<>input
        hashedOutput = :crypto.hash(:sha256,finalstring) |> Base.encode16 |> String.downcase
        checkString = "" |> String.pad_leading(n,"0")
        temp = (checkString == String.slice(hashedOutput,0,n))
        if temp==true do
            IO.puts finalstring<>" "<> hashedOutput
        end
        serverMining(n)      
    end 

    def distributeWork(workerNodeName,n) do
        workerNodeName
        pids = Enum.map(1..8,fn(_) -> Node.spawn(workerNodeName,Project2,:workerMining,[n])end)
        #pid = Node.spawn(workerNodeName,Project2,:workerMining,[n])
        #:timer.sleep(60000)
        listen()
        #Node.spawn_link(workerNodeName,Project2,:workerMining,[2])
    end

    def listen do
            if !Node.alive?() do
                Node.stop()
            else 
                listen()
            end
    end

    def workerMining(n) do
        i = Enum.random(9..16)
        #spawn processes, measure CPU time and find optimum no. of processes
        input = :crypto.strong_rand_bytes(i) |> Base.url_encode64 |> binary_part(0,i)
        finalstring = "rameshwari.oblar;"<>input
        hashedOutput = :crypto.hash(:sha256,finalstring) |> Base.encode16 |> String.downcase
        checkString = "" |> String.pad_leading(n,"0")
        temp = (checkString == String.slice(hashedOutput,0,n))
        if temp==true do
            IO.puts finalstring<>" "<> hashedOutput
        end
        workerMining(n) 
    end
end
