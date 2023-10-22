from tensor import Tensor
from utils.index import Index


struct MNIST[dtype: DType]:
    var data: Tensor[dtype]
    var labels: Tensor[dtype]

    fn __init__(inout self, train: Bool) raises:
        var s = self.read_file(train)
        s = s[find_first(s, "\n")+1:]   # Ignore header

        let N = num_lines(s)                   
        self.data = Tensor[dtype](N, 1, 28, 28)
        self.labels = Tensor[dtype](N)

        let idx_low: Int
        let idx_high: Int
        var idx_line: Int = 0

        # TODO: redo when String .split(",") is supported
        for i in range(N):
            s = s[idx_line:]
            idx_line = find_first(s, "\n") + 1
            self.labels[i] = atol(s[:find_first(s, ",")])
            for m in range(28):
                for n in range(28):
                    idx_low = find_nth(s, ",", 28 * m + n + 1) + 1
                    if m == 27 and n == 27:
                        self.data[Index(i, 0, m, n)] = atol(s[idx_low:idx_line-2])
                    else:
                        idx_high = find_nth(s, ",", 28 * m + n + 2)
                        self.data[Index(i, 0, m, n)] = atol(s[idx_low:idx_high])

            
    @staticmethod
    fn read_file(train: Bool) raises -> String:
        let file_path: String
        let s: String

        if train:
            file_path = "data/mnist_train_small.csv"
        else:
            file_path = "data/mnist_test_small.csv"

        with open(file_path, "r") as f:
            s = f.read()

        return s



fn num_lines(s: String) -> Int:
    var count: Int = 0
    for i in range(len(s)):
        if s[i] == "\n":
            count += 1
    return count


fn find_first(s: String, delimiter: String) -> Int:
    for i in range(len(s)):
        if s[i] == delimiter:
            return i
    return -1


fn find_nth(s: String, delimiter: String, n: Int) -> Int:
    var count: Int = 0
    if n == 0:
        return -1
    for i in range(len(s)):
        if s[i] == delimiter:
            count += 1
            if count == n:
                return i
    return -1


fn cast_string[dtype: DType](s: String) raises -> SIMD[dtype, 1]:
    """"Cast a string with decimal to a SIMD vector of dtype."""
    
    let idx = find_first(s, delimiter=".")
    var x: SIMD[dtype, 1] = -1

    if idx == -1:
        # No decimal point
        x = atol(s)
        return x
    else:
        let c_int: SIMD[dtype, 1]
        let c_frac: SIMD[dtype, 1]
        c_int = atol(s[:idx])
        c_frac = atol(s[idx+1:])
        x = c_int + c_frac / (10 ** len(s[idx+1:]))
        return x