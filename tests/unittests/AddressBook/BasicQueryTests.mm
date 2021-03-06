//******************************************************************************
//
// Copyright (c) 2016 Microsoft Corporation. All rights reserved.
//
// This code is licensed under the MIT License (MIT).
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//******************************************************************************

#include <TestFramework.h>

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#import <AddressBook/ABAddressBook.h>
#import <AddressBook/ABRecord.h>
#import <AddressBook/ABPerson.h>
#import "ABContactInternal.h"
#import "CppWinRTHelpers.h"

using namespace winrt::Windows::ApplicationModel::Contacts;

class AddressBookQueryTest : public ::testing::TestWithParam<::testing::tuple<ABPropertyID, NSString*>> {
protected:
    virtual void SetUp() {
        Contact contact;
        contact.Notes(L"Test Note!");
        contact.Nickname(L"Mikey");
        contact.YomiGivenName(L"Mic");
        contact.HonorificNameSuffix(L"Jr.");
        contact.YomiFamilyName(L"Saw-ft");
        contact.MiddleName(L"Roe");
        contact.LastName(L"Soft");
        contact.HonorificNamePrefix(L"Mr.");
        contact.FirstName(L"Mike");

        ContactJobInfo job;
        job.Title(L"SDE");
        job.Office(L"Redmond");
        job.Manager(L"Satya");
        job.Description(L"I develop good code.");
        job.Department(L"WDG");
        job.CompanyYomiName(L"Mike Roe Soft");
        job.CompanyName(L"Microsoft");
        job.CompanyAddress(L"Redmond, WA");

        contact.JobInfo().Append(job);
        _record = (__bridge_retained ABRecordRef)[[_ABContact alloc] initWithContact:contact andType:kAddressBookNewContact];
    }

    virtual void TearDown() {
        CFRelease(_record);
    }

    ABRecordRef _record;
};

TEST_P(AddressBookQueryTest, BasicContactQuery) {
    ABPropertyID property = ::testing::get<0>(GetParam());
    CFStringRef recordValue = (CFStringRef)ABRecordCopyValue(_record, property);
    ASSERT_OBJCEQ_MSG(::testing::get<1>(GetParam()), (__bridge NSString*)recordValue, "FAILED: Incorrect property copied!\n");
    CFRelease(recordValue);
}

INSTANTIATE_TEST_CASE_P(AddressBook,
                        AddressBookQueryTest,
                        ::testing::Values(::testing::make_tuple(kABPersonNoteProperty, @"Test Note!"),
                                          ::testing::make_tuple(kABPersonNicknameProperty, @"Mikey"),
                                          ::testing::make_tuple(kABPersonFirstNamePhoneticProperty, @"Mic"),
                                          ::testing::make_tuple(kABPersonSuffixProperty, @"Jr."),
                                          ::testing::make_tuple(kABPersonLastNamePhoneticProperty, @"Saw-ft"),
                                          ::testing::make_tuple(kABPersonMiddleNameProperty, @"Roe"),
                                          ::testing::make_tuple(kABPersonLastNameProperty, @"Soft"),
                                          ::testing::make_tuple(kABPersonPrefixProperty, @"Mr."),
                                          ::testing::make_tuple(kABPersonFirstNameProperty, @"Mike"),
                                          ::testing::make_tuple(kABPersonJobTitleProperty, @"SDE"),
                                          ::testing::make_tuple(kABPersonDepartmentProperty, @"WDG"),
                                          ::testing::make_tuple(kABPersonOrganizationProperty, @"Microsoft"),
                                          ::testing::make_tuple(-1, nil)));

TEST(AddressBook, QueryContactBirthday) {
    Contact contact;
    ContactDate birthday;
    birthday.Year(objcwinrt::optional(1975));
    birthday.Month(objcwinrt::optional(4u));
    birthday.Day(objcwinrt::optional(4u));
    birthday.Kind(ContactDateKind::Birthday);

    contact.ImportantDates().Append(birthday);
    ABRecordRef record = (__bridge_retained ABRecordRef)[[_ABContact alloc] initWithContact:contact andType:kAddressBookNewContact];

    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = 4;
    dateComponents.month = 4;
    dateComponents.year = 1975;
    NSDate* date = [calendar dateFromComponents:dateComponents];
    CFDateRef contactBirthday = (CFDateRef)ABRecordCopyValue(record, kABPersonBirthdayProperty);
    ASSERT_TRUE_MSG([[NSCalendar currentCalendar] isDate:(__bridge NSDate*)contactBirthday inSameDayAsDate:date],
                    "FAILED: Dates should be on the same day!\n");
    CFRelease(record);
    CFRelease(contactBirthday);
    [dateComponents release];
}

TEST(AddressBook, GetRecordTypeAndID) {
    ASSERT_EQ_MSG(kABRecordInvalidID, ABRecordGetRecordID(nullptr), "FAILED: null record should have an invalid ID!\n");
    ABRecordRef record =
        (__bridge_retained ABRecordRef)[[_ABContact alloc] initWithContact:Contact() andType:kAddressBookNewContact];
    ASSERT_EQ_MSG(kABPersonType, ABRecordGetRecordType(record), "FAILED: Person record should have a person type!\n");
    CFRelease(record);
}