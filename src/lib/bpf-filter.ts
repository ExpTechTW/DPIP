
interface SOSStage {
  b0: number;
  b1: number;
  b2: number;
  a1: number;
  a2: number;
  z1: number;
  z2: number;
}

export class BPFFilter {
  private stages: SOSStage[];

  constructor(num: number[][], den: number[][]) {
    if (num.length !== den.length) {
      throw new Error('num/den length mismatch');
    }

    this.stages = num.map((numCoeffs, i) => {
      const [b0, b1, b2] = numCoeffs;
      const [a0, a1, a2] = den[i];

      if (a0 !== 1.0) {
        return {
          b0: b0 / a0,
          b1: b1 / a0,
          b2: b2 / a0,
          a1: a1 / a0,
          a2: a2 / a0,
          z1: 0,
          z2: 0,
        };
      }

      return {
        b0,
        b1,
        b2,
        a1,
        a2,
        z1: 0,
        z2: 0,
      };
    });
  }

  apply(x: number): number {
    let y = x;
    for (let i = 0; i < this.stages.length; i++) {
      const stage = this.stages[i];
      const out = stage.b0 * y + stage.z1;
      stage.z1 = stage.b1 * y - stage.a1 * out + stage.z2;
      stage.z2 = stage.b2 * y - stage.a2 * out;
      y = out;
    }
    return y;
  }

  applyBuffer(x: number[]): number[] {
    return x.map((val) => this.apply(val));
  }

  reset(): void {
    for (const stage of this.stages) {
      stage.z1 = 0;
      stage.z2 = 0;
    }
  }
}

const NUM_LPF: number[][] = [
  [0.8063260828207, 0, 0],
  [1, -0.3349099821478, 1],
  [0.8764452158503, 0, 0],
  [1, -0.08269016387548, 1],
  [0.8131516681065, 0, 0],
  [1, 0.5521204464881, 1],
  [1.228277124762, 0, 0],
  [1, 1.705652561121, 1],
  [0.00431639855615, 0, 0],
  [1, -0.4218227257396, 1],
  [1, 0, 0],
];

const DEN_LPF: number[][] = [
  [1, 0, 0],
  [1, -0.6719798550872, 0.938845023254],
  [1, 0, 0],
  [1, -0.8264759910073, 0.8561761588872],
  [1, 0, 0],
  [1, -1.10962299915, 0.7141202529829],
  [1, 0, 0],
  [1, -1.413006561919, 0.5638384962434],
  [1, 0, 0],
  [1, -0.6139497794955, 0.9834048810788],
  [1, 0, 0],
];

const NUM_HPF: number[][] = [
  [0.9769037485204, 0, 0],
  [1, -2, 1],
  [0.9424328308459, 0, 0],
  [1, -2, 1],
  [0.9149691441131, 0, 0],
  [1, -2, 1],
  [0.8959987277275, 0, 0],
  [1, -2, 1],
  [0.8863374802187, 0, 0],
  [1, -2, 1],
  [1, 0, 0],
];

const DEN_HPF: number[][] = [
  [1, 0, 0],
  [1, -1.946073828052, 0.9615411660298],
  [1, 0, 0],
  [1, -1.877404882092, 0.8923264412918],
  [1, 0, 0],
  [1, -1.822694925196, 0.837181651256],
  [1, 0, 0],
  [1, -1.78490427193, 0.7990906389804],
  [1, 0, 0],
  [1, -1.765658260281, 0.7796916605933],
  [1, 0, 0],
];

export function createBPFFilter(): { hpf: BPFFilter; lpf: BPFFilter } {
  return {
    hpf: new BPFFilter(NUM_HPF, DEN_HPF),
    lpf: new BPFFilter(NUM_LPF, DEN_LPF),
  };
}

export function applyBPF(data: number[], hpf: BPFFilter, lpf: BPFFilter): number[] {
  hpf.reset();
  lpf.reset();
  let filtered = hpf.applyBuffer(data);
  filtered = lpf.applyBuffer(filtered);
  return filtered;
}

