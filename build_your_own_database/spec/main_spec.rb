describe 'database' do
    before do
        `rm -rf test.db`
    end
    def run_script(commands)
        raw_output = nil
        IO.popen("/Users/matt/Developer/My-Build-Your-Own-X/build_your_own_database/src/main", "r+") do |pipe|
            commands.each do |command|
                pipe.puts command
            end

            pipe.close_write
            
            #read entire output
            raw_output = pipe.gets(nil)
        end
        raw_output.split("\n")
    end

    it 'inserts and retrieves a row' do
        result = run_script([
            "insert 1 user1 person1@example.com",
            "select",
            ".exit",
        ])
        expect(result).to match_array([
            "db > Executed.",
            "db > (1, user1, person1@example.com)",
            "Executed.",
            "db > ",
        ])
    end

    it 'prints error message when table is full' do
        script = (1..1401).map do |i|
            "insert #{i} user#{i} person#{i}@example.com"
        end
        script << ".exit"
        result = run_script(script)
        expect(result[-2]).to eq('db > Error: Table Full.')
    end

    it 'allows inserting strings that are the maximum length' do
        long_username = 'a'*32
        long_email = 'a'*255
        script = [
            "insert 1 #{long_username} #{long_email}",
            "select",
            ".exit",
        ]
        result = run_script(script)
        expect(result).to match_array([
            "db > Executed.",
            "db > (1, #{long_username}, #{long_email})",
            "Executed.",
            "db > ",
        ])
    end

    it 'Errors out if strings are too long' do
        long_username = 'a'*33
        long_email = 'a'*255
        script = [
            "insert 1 #{long_username} #{long_email}",
            "select",
            ".exit",
        ]
        result = run_script(script)
        expect(result).to match_array([
            "db > Error: Strings are too long.",
            "db > Executed.",
            "db > ",
        ])
    end

    it 'Errors out if id is negative' do
        script = [
            "insert -1 foo foo@bar.com",
            "select",
            ".exit",
        ]
        result = run_script(script);
        expect(result).to match_array([
            "db > Error: ID cannot be negative.",
            "db > Executed.",
            "db > ",
        ])
    end

    it 'Exhibits persistence with data' do
        result1 = run_script([
            "insert 1 foo foo@bar.com",
            ".exit",
        ])
        expect(result1).to match_array([
            "db > Executed.",
            "db > ",
        ])
        result2 = run_script([
            "select",
            ".exit",
        ])
        expect(result2).to match_array([
            "db > (1, foo, foo@bar.com)",
            "Executed.",
            "db > ",
        ])
    end
end