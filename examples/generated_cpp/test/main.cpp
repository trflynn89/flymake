#include "foo/generated.hpp"
#include "bar/generated.hpp"

#include <cassert>
#include <iostream>

int main()
{
    fly::GeneratedFoo foo(15);
    assert(foo() == 15);

    fly::GeneratedBar bar(25);
    assert(bar() == 25);

    std::cout << "Passed!\n";
    return 0;
}
