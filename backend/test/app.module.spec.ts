process.env.JWT_SECRET ??= 'test-secret';

import { AppModule } from '../src/modules/app.module';

describe('AppModule', () => {
  it('should be defined', () => {
    expect(AppModule).toBeDefined();
  });
});
