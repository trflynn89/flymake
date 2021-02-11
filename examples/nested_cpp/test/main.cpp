#include "nested_cpp/outer_lib/inner_lib/inner_lib.hpp"
#include "nested_cpp/outer_lib/outer_lib.hpp"

#include <cassert>
#include <iostream>

int main()
{
    assert(outer::outer_value() == 123);
    assert(inner::outer_value() == 123);
    assert(inner::inner_value() == 1989);

    std::cout << "Passed!\n";
    return 0;
}
