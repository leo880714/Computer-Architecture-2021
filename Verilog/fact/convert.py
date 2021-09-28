import binascii

# -------------------------- Loading List -------------------------- 
f = open("fact_text.txt", "r")
instruction_list = []
counter = 0
for line in f.readlines():
    counter += 1
    x = line
    tmp = (bin(int(x, 16))[2:].zfill(32))

    opcode = tmp[25:32]
    funct3 = tmp[17:20]
    funct7 = tmp[0:7]
    rd = tmp[20:25]
    rs1 = tmp[12:17]
    rs2 = tmp[7:12]
    rd_d = int(rd, 2)
    rs1_d = int(rs1, 2)
    rs2_d = int(rs2, 2)
    i_type = ''
    instruction = ''
    if (opcode == '0110011' and funct3 ==  '000' and funct7 == '0000000'): 
        i_type = "ADD"
        instruction = f'{i_type}, x{rd_d}, x{rs1_d}, x{rs2_d}'
    elif (opcode == '0110011' and funct3 ==  '000' and funct7 == '0100000'): 
        i_type = 'SUB'
        instruction = f'{i_type}, x{rd_d}, x{rs1_d}, x{rs2_d}'
    elif (opcode == '0010011' and funct3 ==  '000'): 
        i_type = 'ADDI'
        siim_12 = tmp[0:12]
        siim_12_d = int(siim_12, 2)
        instruction = f'{i_type}, x{rd_d}, x{rs1_d}, {siim_12_d}'
    elif (opcode == '0010011' and funct3 ==  '010'): 
        i_type = 'SLTI'
        siim_12 = tmp[0:12]
        siim_12_d = int(siim_12, 2)
        instruction = f'{i_type}, x{rd_d}, x{rs1_d}, {siim_12_d}'
    elif (opcode == '1101111'): 
        i_type = 'JAL'
        instruction = f'{i_type}, x{rd_d}'
    elif (opcode == '1100111' and funct3 == '000'): 
        i_type = 'JALR'   
        siim_12 = tmp[0:12]
        siim_12_d = int(siim_12, 2)
        instruction = f'{i_type}, x{rd_d}, x{rs1_d}, {siim_12_d}'
    elif (opcode == '1100011' and funct3 == '000'): 
        i_type = 'BEQ'
        instruction = f'{i_type}, x{rs1_d}, x{rs2_d}, siim_13'
    elif (opcode == '0010111'): 
        i_type = 'AUIPC'
        instruction = f'{i_type}, x{rd_d}, uiim_20'
    elif (opcode == '0000011' and funct3 == '010'): 
        i_type = 'LW'
        siim_12 = tmp[0:12]
        siim_12_d = int(siim_12, 2)
        instruction = f'{i_type}, x{rd_d}, x{rs1_d}, {siim_12_d}'
    elif (opcode == '0100011' and funct3 == '010'): 
        i_type = 'SW'
        siim_12 = tmp[0:12]
        siim_12_d = int(siim_12, 2)
        instruction = f'{i_type}, x{rs2_d}, x{rs1_d}, {siim_12_d}'
    print("{} -> {} | {} | {} | {} | {} | {} -> {}".format(counter, tmp[0:7], tmp[7:12], tmp[12:17], tmp[17:20], tmp[20:25], tmp[25:32], instruction))
    instruction_list.append(instruction)
    #print(binary_string)

with open('instructions.txt', "w") as fhandle:
  for line in instruction_list:
    fhandle.write(f'{line}\n')