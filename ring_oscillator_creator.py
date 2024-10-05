import random
import os

def clamp(value, min_val, max_val):
    return max(min(value, max_val), min_val)

def generate_variation(nominal, sigma, tolerance):
    variation = random.gauss(0, sigma * nominal)
    clamped_variation = clamp(variation, -tolerance * nominal, tolerance * nominal)
    return clamped_variation

# NAND gate and inverter templates
nand_template = """X1 enable in feedback vdd vss nand tplv={tplv:.4e} tpwv={tpwv:.4e} tnlv={tnlv:.4e} tnwv={tnwv:.4e} tpotv={tpotv:.4e} tnotv={tnotv:.4e}
"""
inverter_template = """X{} {} {} vdd vss inverter tplv={tplv:.4e} tpwv={tpwv:.4e} tnlv={tnlv:.4e} tnwv={tnwv:.4e} tpotv={tpotv:.4e} tnotv={tnotv:.4e}
"""

# Get the directory of the current script
script_dir = os.path.dirname(os.path.abspath(__file__))

for i in range(8):
    variations = {
        'tplv': generate_variation(130e-9, 0.065, 0.15),
        'tpwv': generate_variation(260e-9, 0.065, 0.15),
        'tnlv': generate_variation(130e-9, 0.065, 0.15),
        'tnwv': generate_variation(130e-9, 0.065, 0.15),
        'tpotv': generate_variation(2.5e-9, 0.05, 0.10),
        'tnotv': generate_variation(2.5e-9, 0.05, 0.10)
    }
    
    # Create the full path for the output file
    file_path = os.path.join(script_dir, f"ring_oscillator_{i}.cir")
    
    try:
        with open(file_path, "w") as f:
            f.write(f".subckt ro_{i} enable out vdd vss\n")
            
            # Write NAND gate
            f.write(nand_template.format(**variations))
            
            # Write 12 inverters
            for j in range(2, 14):  # Start from 2 because NAND is X1
                in_node = "feedback" if j == 2 else f"n{j-1}"
                out_node = f"n{j}" if j < 13 else "out"
                f.write(inverter_template.format(j, in_node, out_node, **variations))
            
            # Add feedback connection
            f.write("* Feedback connection\n")
            f.write("* 1 ohm resistor for feedback\n")
            f.write("Rfeedback out in 1\n")
            
            f.write(f".ends ro_{i}\n")
        print(f"Generated ring_oscillator_{i}.cir")
        
        # Print the variations for this oscillator
        print(f"Variations for oscillator {i}:")
        for key, value in variations.items():
            print(f"  {key}: {value:.4e}")
        print()
    except PermissionError:
        print(f"Permission denied when trying to write ring_oscillator_{i}.cir")
        print(f"Attempted to write to: {file_path}")

print("Script execution completed.")